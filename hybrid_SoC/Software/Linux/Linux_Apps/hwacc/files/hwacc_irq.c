/*  hwacc.c - The simplest kernel module.

* Copyright (C) 2013-2022 Xilinx, Inc
* Copyright (c) 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
*
*   This program is free software; you can redistribute it and/or modify
*   it under the terms of the GNU General Public License as published by
*   the Free Software Foundation; either version 2 of the License, or
*   (at your option) any later version.

*   This program is distributed in the hope that it will be useful,
*   but WITHOUT ANY WARRANTY; without even the implied warranty of
*   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*   GNU General Public License for more details.
*
*   You should have received a copy of the GNU General Public License along
*   with this program. If not, see <http://www.gnu.org/licenses/>.

*/


#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/module.h>
#include <linux/slab.h>
#include <linux/io.h>
#include <linux/interrupt.h>

#include <linux/of_address.h>
#include <linux/of_device.h>
#include <linux/of_platform.h>

#include <linux/gpio.h> 
#include <linux/swab.h>  
#include <linux/semaphore.h>
#include <linux/wait.h>

#include <linux/types.h>
#include <linux/skbuff.h>
#include <linux/socket.h>
#include <linux/etherdevice.h>
#include <linux/netdevice.h>
#include <linux/rtnetlink.h>
#include <linux/refcount.h>
#include <net/genetlink.h>
#include <linux/phy.h>
#include <linux/byteorder/generic.h>
#include <linux/if_arp.h>

 
#include <linux/mm.h>     
#include <crypto/aead.h>

#include <linux/hwacc.h>


/* Standard module information, edit as appropriate */
/* Meta Information */
MODULE_LICENSE("GPL");
MODULE_AUTHOR("Sebastian Lintl, Lukas Fuereder");
MODULE_DESCRIPTION("Linux Kernel Thread, which processes network packets and transmits them via DMA to PL AES.");


#define DRIVER_NAME "hwacc"

//###############################################################################
//#####################################FPGA######################################
//###############################################################################





static DECLARE_COMPLETION(crypting_done);



#define PAGE_SIZE 4096
#define PAGE_SIZE_DR 8192
#define BRAM_BASE_rx 0xA0008000
#define BRAM_BASE_tx 0xA0000000

#define DATA_READY_rx 0xA0010000
#define DATA_READY_tx 0xA0020000

#define KRITIS3M_HEADER_SIZE 16
#define KRITIS3M_SIZE_FIELD_OFFSET 12 


/* Global Variables */
static struct kritis3m_egress_queue *egress_driver;
static int thread_ID = 1;

/* initialization macro for the work list of the kernel thread*/
LIST_HEAD(WORK_LIST);


static void __iomem *mapped_base_tx = NULL;  // Store pre-mapped address
static void __iomem *mapped_base_rx = NULL;  // Store pre-mapped address

static void __iomem *mapped_base_DR_tx = NULL;  // Store pre-mapped address
static void __iomem *mapped_base_DR_rx = NULL;  // Store pre-mapped address


//Function to write to memory
void write_to_memory_tx(off_t address, uint64_t value) {

	off_t page_base = address & ~(PAGE_SIZE - 1);
	off_t page_offset = address - page_base;

    if (!mapped_base_tx) {
        pr_notice("Error: Memory not mapped. Call init_tx_BRAM_FPGA() first.\n");
        return;
    }

    // Write the value to the specified memory address
    volatile uint64_t __iomem *mapped_address = (volatile uint64_t __iomem *)((char *)mapped_base_tx + page_offset);
    writeq(value, mapped_address); // Use writeq for 64-bit writes

}

void write_to_memory_rx(off_t address, uint64_t value) {

	off_t page_base = address & ~(PAGE_SIZE - 1);
	off_t page_offset = address - page_base;

    if (!mapped_base_rx) {
        pr_notice("Error: Memory not mapped. Call init_rx_BRAM_FPGA() first.\n");
        return;
    }

    // Write the value to the specified memory address
    volatile uint64_t __iomem *mapped_address = (volatile uint64_t __iomem *)((char *)mapped_base_rx + page_offset);
    writeq(value, mapped_address); // Use writeq for 64-bit writes

}

uint64_t read_from_memory_tx(off_t address) {

	uint64_t value;

	off_t page_base = address & ~(PAGE_SIZE - 1);
	off_t page_offset = address - page_base;

    // read the value to the specified memory address tx
    volatile uint64_t __iomem *mapped_address = (volatile uint64_t __iomem *)((char *)mapped_base_tx + page_offset);
    value = readq(mapped_address); 


	return value;
}

uint64_t read_from_memory_rx(off_t address) {

	uint64_t value;

	off_t page_base = address & ~(PAGE_SIZE - 1);
	off_t page_offset = address - page_base;

    // read the value to the specified memory address rx
    volatile uint64_t __iomem *mapped_address = (volatile uint64_t __iomem *)((char *)mapped_base_rx + page_offset);
	value = readq(mapped_address); 


	return value;
}

void write_to_memory_DR(void __iomem *mapped_base_DR, off_t address, uint64_t value) {

	off_t page_base = address & ~(PAGE_SIZE_DR - 1);
	off_t page_offset = address - page_base;

    if (!mapped_base_DR) {
        pr_notice("Error: Memory not mapped.\n");
        return;
    }

    // Write the value to the specified memory address
    volatile uint64_t __iomem *mapped_address = (volatile uint64_t __iomem *)((char *)mapped_base_DR + page_offset);

	pr_notice("Writing value 0x%016llX to address 0x%p (offset 0x%lx)\n", value, mapped_address, (unsigned long)page_offset);

	writel(value, mapped_address); // Use writel for 32-bit writes

}

uint64_t read_from_memory_DR(void __iomem *mapped_base_DR) {
	uint64_t value;

    // read the value to the specified memory address 
    volatile uint64_t __iomem *mapped_address = (volatile uint64_t __iomem *)((char *)mapped_base_DR);
    value = readq(mapped_address); 

	return value;
}








static irqreturn_t gpio_irq_handler(int irq, void *dev_id) {
    pr_info("GPIO interrupt triggered for IRQ: %d\n", irq);

    complete(&crypting_done);  // Wake up the waiting function
    return IRQ_HANDLED;
}



// ** Initialize the Interrupt for GPIOs **
int init_crypting_irq(void)
{
    int irq_gpio0, irq_gpio1;

    irq_gpio0 = gpio_to_irq(505);  // GPIO pin 504 (axi_gpio_0)
    irq_gpio1 = gpio_to_irq(507);  // GPIO pin 506 (axi_gpio_1)

    if (irq_gpio0 < 0 || irq_gpio1 < 0) {
        pr_err("Failed to get IRQ numbers from GPIOs\n");
        return -EINVAL;
    }

    if (request_irq(irq_gpio0, gpio_irq_handler, IRQF_TRIGGER_RISING, "gpio0_irq", NULL)) {
         pr_err("Failed to request IRQ for GPIO 504\n");
         return -EIO;
    }

    if (request_irq(irq_gpio1, gpio_irq_handler, IRQF_TRIGGER_RISING, "gpio1_irq", NULL)) {
         pr_err("Failed to request IRQ for GPIO 506\n");
         free_irq(irq_gpio0, NULL);  // Clean up first IRQ
         return -EIO;
    } 

    // Write to memory to set up Data Ready signals
    write_to_memory_DR(mapped_base_DR_rx, DATA_READY_rx + 0x11c, 0x80000000);
    write_to_memory_DR(mapped_base_DR_tx, DATA_READY_tx + 0x11c, 0x80000000);

    write_to_memory_DR(mapped_base_DR_rx, DATA_READY_rx + 0x128, 0x00000001);
    write_to_memory_DR(mapped_base_DR_tx, DATA_READY_tx + 0x128, 0x00000001);

    pr_info("GPIO interrupt handlers successfully registered\n");
    return 0;
}


// ** Cleanup Function for IRQs **
void cleanup_crypting_irq(void) {
    int irq_gpio0 = gpio_to_irq(505);
    int irq_gpio1 = gpio_to_irq(507);

    free_irq(irq_gpio0, NULL);
    free_irq(irq_gpio1, NULL);

    pr_info("GPIO interrupt handlers unregistered\n");
}



// ** Function to Wait for Crypting Process **
//** Function to Wait for Crypting Process **
void wait_for_crypting(struct kritis3m_queue_element *work_item) {
 
	reinit_completion(&crypting_done); 

    wait_for_completion(&crypting_done);
}





static int init_tx_key_FPGA(char *key, int key_len) {
    if (key_len < 32) {  // Ensure the key is at least 256 bits (32 bytes)
        pr_notice("Error: key length must be at least 32 bytes\n");
        return -1;
    }



    // Split the key into 64-bit chunks
    uint64_t part1, part2, part3, part4;

    memcpy(&part1, key, sizeof(uint64_t));
    write_to_memory_tx(BRAM_BASE_tx + 0x10, part1);

    memcpy(&part2, key + sizeof(uint64_t), sizeof(uint64_t));
    write_to_memory_tx(BRAM_BASE_tx + 0x18, part2);

    memcpy(&part3, key + 2 * sizeof(uint64_t), sizeof(uint64_t));
    write_to_memory_tx(BRAM_BASE_tx + 0x20, part3);

    memcpy(&part4, key + 3 * sizeof(uint64_t), sizeof(uint64_t));
    write_to_memory_tx(BRAM_BASE_tx + 0x28, part4);

    return 0;
}

static int init_rx_key_FPGA(char *key, int key_len) {
    if (key_len < 32) {  // Ensure the key is at least 256 bits (32 bytes)
        pr_notice("Error: key length must be at least 32 bytes\n");
        return -1;
    }

    // Split the key into 64-bit chunks
    uint64_t part1, part2, part3, part4;

    memcpy(&part1, key, sizeof(uint64_t));
    write_to_memory_rx(BRAM_BASE_rx + 0x10, part1);

    memcpy(&part2, key + sizeof(uint64_t), sizeof(uint64_t));
    write_to_memory_rx(BRAM_BASE_rx + 0x18, part2);

    memcpy(&part3, key + 2 * sizeof(uint64_t), sizeof(uint64_t));
    write_to_memory_rx(BRAM_BASE_rx + 0x20, part3);

    memcpy(&part4, key + 3 * sizeof(uint64_t), sizeof(uint64_t));
    write_to_memory_rx(BRAM_BASE_rx + 0x28, part4);

    return 0;
}


void init_tx_BRAM_FPGA(void) {
    void __iomem *mapped_base; // Pointer to the mapped memory
	off_t address = BRAM_BASE_tx;
    // Align the address to the page size
    off_t page_base = address & ~(PAGE_SIZE - 1);
    

    // Map the physical memory to kernel virtual address space
    mapped_base_tx = ioremap(page_base, PAGE_SIZE);

    if (!mapped_base_tx) {
        pr_notice("Error mapping memory\n");
        return;
    }

	address = DATA_READY_tx;
    // Align the address to the page size
    page_base = address & ~(PAGE_SIZE_DR - 1);
    

    // Map the physical memory to kernel virtual address space
    mapped_base_DR_tx = ioremap(page_base, PAGE_SIZE_DR);

    if (!mapped_base_DR_tx) {
        pr_notice("Error: mapping memory\n");
        return;
    }
}

void init_rx_BRAM_FPGA(void) {
    void __iomem *mapped_base; // Pointer to the mapped memory
	off_t address = BRAM_BASE_rx;
    // Align the address to the page size
    off_t page_base = address & ~(PAGE_SIZE - 1);
    

    // Map the physical memory to kernel virtual address space
    mapped_base_rx = ioremap(page_base, PAGE_SIZE);

    if (!mapped_base_rx) {
        pr_notice("Error: mapping memory\n");
        return;
    }


	address = DATA_READY_rx;
    // Align the address to the page size
    page_base = address & ~(PAGE_SIZE_DR - 1);
    

    // Map the physical memory to kernel virtual address space
    mapped_base_DR_rx = ioremap(page_base, PAGE_SIZE_DR);

    if (!mapped_base_DR_rx) {
        pr_notice("Error: mapping memory\n");
        return;
    }
}


void init_tx_IV_FPGA(struct aead_request *req)
{
	uint64_t temp;
	unsigned int cryptlen = ((uint64_t)req->cryptlen);
	unsigned int assoclen = ((uint64_t)req->assoclen);
	unsigned char *iv_string = req->iv;

	//0x30-0x37 IV
	memcpy(&temp, iv_string, sizeof(uint64_t));
	write_to_memory_tx(BRAM_BASE_tx + 0x30, temp);

	//0x38-0x3b IV	0x3c-03f payload size
	memcpy(&temp, iv_string + sizeof(uint64_t), sizeof(uint64_t));
	temp = (temp & 0x00000000FFFFFFFF) | ((uint64_t)cryptlen << 32);
	temp = (temp & 0x0000FFFFFFFFFFFF) | ((uint64_t)assoclen << 48);
	write_to_memory_tx(BRAM_BASE_tx + 0x38, temp);

}


void init_rx_IV_FPGA(struct aead_request *req)
{
	uint64_t temp;
	unsigned int cryptlen = ((uint64_t)req->cryptlen);
	unsigned int assoclen = ((uint64_t)req->assoclen);
    unsigned char *iv_string = req->iv;

	cryptlen=cryptlen-0x10;

	//0x30-0x37 IV
	memcpy(&temp, iv_string, sizeof(uint64_t));
	write_to_memory_rx(BRAM_BASE_rx + 0x30, temp);

	//0x38-0x3b IV	0x3c-03f payload size
	memcpy(&temp, iv_string + sizeof(uint64_t), sizeof(uint64_t));
	temp = (temp & 0x00000000FFFFFFFF) | ((uint64_t)cryptlen << 32);
	temp = (temp & 0x0000FFFFFFFFFFFF) | ((uint64_t)assoclen << 48);
	write_to_memory_rx(BRAM_BASE_rx + 0x38, temp);

}

void write_tx_associateddata_FPGA(struct aead_request *req)
{
	unsigned int offset = 0x40;
	unsigned int sg_offset = 0;
	unsigned int processed;
	uint64_t temp_buffer;

    unsigned int cryptlen = ((uint64_t)req->cryptlen);
	unsigned int assoclen = ((uint64_t)req->assoclen);
	unsigned int data_len = assoclen+0x08;

	struct scatterlist *sg = req->src; 

    
	for (int i = 0; i < data_len / sizeof(uint64_t); i++) {
		while (sg && sg_offset >= sg->length) {
			sg = sg_next(sg);
			sg_offset = 0;
		}

		if (!sg) {
			pr_notice("Error: Not enough data in scatterlist\n");
			break;
		}

		//Get the virtual address of the current scatterlist entry
		uint8_t *sg_data = sg_virt(sg);

		size_t remaining_bytes = assoclen - processed; // Bytes left to process

		temp_buffer = 0;

		if (remaining_bytes < sizeof(uint64_t)) {
			// If less than 8 bytes remain, pad the rest with 0s
			memcpy(&temp_buffer, sg_data + sg_offset, remaining_bytes); // Copy into partloop
		} else {
			// Normal case: Copy full 8-byte block
			memcpy(&temp_buffer, sg_data + sg_offset, sizeof(uint64_t));
			
		}
	
		//Write the block to memory
		write_to_memory_tx(BRAM_BASE_tx + offset, temp_buffer);

		//Advance the scatterlist offset and output memory offset
		sg_offset += sizeof(uint64_t);
		offset += sizeof(uint64_t);
		processed += sizeof(uint64_t);
	}
}

void write_rx_associateddata_FPGA(struct aead_request *req)
{
	unsigned int offset = 0x40;
	unsigned int sg_offset = 0;
	unsigned int processed;
	uint64_t temp_buffer;

	unsigned int cryptlen = ((uint64_t)req->cryptlen);
	unsigned int assoclen = ((uint64_t)req->assoclen);
	unsigned int data_len = assoclen+0x08;

	struct scatterlist *sg = req->src; 

   
	for (int i = 0; i < data_len / sizeof(uint64_t); i++) {
		while (sg && sg_offset >= sg->length) {
			sg = sg_next(sg);
			sg_offset = 0;
		}

		if (!sg) {
			pr_notice("Error: Not enough data in scatterlist\n");
			break;
		}

		//Get the virtual address of the current scatterlist entry
		uint8_t *sg_data = sg_virt(sg);

		size_t remaining_bytes = assoclen - processed; // Bytes left to process

		temp_buffer = 0;

		if (remaining_bytes < sizeof(uint64_t)) {
			// If less than 8 bytes remain, pad the rest with 0s
			memcpy(&temp_buffer, sg_data + sg_offset, remaining_bytes); // Copy into partloop
		} else {
			// Normal case: Copy full 8-byte block
			memcpy(&temp_buffer, sg_data + sg_offset, sizeof(uint64_t));
		}
	
		//Write the block to memory
		write_to_memory_rx(BRAM_BASE_rx + offset, temp_buffer);

		//Advance the scatterlist offset and output memory offset
		sg_offset += sizeof(uint64_t);
		offset += sizeof(uint64_t);
		processed += sizeof(uint64_t);
	}
}


void write_tx_payload_FPGA(struct aead_request *req)
{
	unsigned int offset = 0x100;
	unsigned int sg_offset = 0;
	unsigned int processed;
	uint64_t temp_buffer;

	unsigned int cryptlen = ((uint64_t)req->cryptlen);
	unsigned int assoclen = ((uint64_t)req->assoclen);
	unsigned int data_len = cryptlen+0x08;
	
	struct scatterlist *sg = req->src;


	sg_offset = assoclen;
   
	for (int i = 0; i < data_len / sizeof(uint64_t); i++) {
		while (sg && sg_offset >= sg->length) {
			sg = sg_next(sg);
			sg_offset = 0;
		}

		if (!sg) {
			pr_notice("Error: Not enough data in scatterlist\n");
			break;
		}

		//Get the virtual address of the current scatterlist entry
		uint8_t *sg_data = sg_virt(sg);

		size_t remaining_bytes = cryptlen - processed; // Bytes left to process

		temp_buffer = 0;

		if (remaining_bytes < sizeof(uint64_t)) {
			// If less than 8 bytes remain, pad the rest with 0s
			memcpy(&temp_buffer, sg_data + sg_offset, remaining_bytes); // Copy into partloop
			write_to_memory_tx(BRAM_BASE_tx + offset, temp_buffer);
		} else {
			// Normal case: Copy full 8-byte block
			memcpy(&temp_buffer, sg_data + sg_offset, sizeof(uint64_t));
			write_to_memory_tx(BRAM_BASE_tx + offset, temp_buffer);
		}

		//Advance the scatterlist offset and output memory offset
		sg_offset += sizeof(uint64_t);
		offset += sizeof(uint64_t);
		processed += sizeof(uint64_t);
	}

	write_to_memory_DR(mapped_base_DR_tx, DATA_READY_tx + 0x8, 1);
}


void write_rx_payload_FPGA(struct aead_request *req)
{
	unsigned int offset = 0x100;
	unsigned int sg_offset = 0;
	unsigned int processed;
	uint64_t temp_buffer;

	unsigned int cryptlen = ((uint64_t)req->cryptlen);
	unsigned int assoclen = ((uint64_t)req->assoclen);
	unsigned int data_len = cryptlen + 0x08;

	struct scatterlist *sg = req->src; 


	sg_offset = assoclen;
   
	for (int i = 0; i < data_len / sizeof(uint64_t); i++) {
		while (sg && sg_offset >= sg->length) {
			sg = sg_next(sg);
			sg_offset = 0;
		}

		if (!sg) {
			pr_notice("Error: Not enough data in scatterlist\n");
			break;
		}

		//Get the virtual address of the current scatterlist entry
		uint8_t *sg_data = sg_virt(sg);

		size_t remaining_bytes = data_len - processed; // Bytes left to process

		temp_buffer = 0;

		if (remaining_bytes < sizeof(uint64_t)) {
			// If less than 8 bytes remain, pad the rest with 0s
			memcpy(&temp_buffer, sg_data + sg_offset, remaining_bytes); // Copy into partloop
			write_to_memory_rx(BRAM_BASE_rx + offset, temp_buffer);
		} else {
			// Normal case: Copy full 8-byte block
			memcpy(&temp_buffer, sg_data + sg_offset, sizeof(uint64_t));
			write_to_memory_rx(BRAM_BASE_rx + offset, temp_buffer);
		}
	
	

		//Advance the scatterlist offset and output memory offset
		sg_offset += sizeof(uint64_t);
		offset += sizeof(uint64_t);
		processed += sizeof(uint64_t);
	}

	write_to_memory_DR(mapped_base_DR_rx, DATA_READY_rx + 0x8, 1);

}




int read_tx_payload_FPGA(struct aead_request *req) {
    int ret = 0;
    unsigned int offset = 0x100;
    unsigned int sg_offset = req->assoclen;
    unsigned int processed = 0;
    uint64_t temp_buffer = 0;

    unsigned int cryptlen = req->cryptlen;
    unsigned int icv_offset = (cryptlen + 0xF) & ~0xF; // Align to next 16-byte boundary
    struct scatterlist *sg = req->dst;
    uint8_t *sg_data = sg_virt(sg);

    while (processed < cryptlen && sg) {
        if (sg_offset >= sg->length) {
            sg = sg_next(sg);
            if (!sg) {
                pr_notice("Scatterlist exhausted, stopping further writes.\n");
                break;
            }
            sg_offset = 0;
            sg_data = sg_virt(sg);
        }

        temp_buffer = read_from_memory_tx(BRAM_BASE_tx + offset);

        // Prevent buffer overflow in scatterlist writes
        if (sg_offset + sizeof(uint64_t) <= sg->length) {
            memcpy(sg_data + sg_offset, &temp_buffer, sizeof(uint64_t));
        } else {
            pr_notice("Warning: Scatterlist buffer too small, truncating copy.\n");
            break;
        }

        sg_offset += sizeof(uint64_t);
        offset += sizeof(uint64_t);
        processed += sizeof(uint64_t);
    }

	unsigned int icv_offset1 =BRAM_BASE_tx + 0x100 + icv_offset;
	unsigned int icv_offset2 =BRAM_BASE_tx + 0x100 + icv_offset + sizeof(uint64_t);

    // Read two times uint64 from icv_offset to (cryptlen + assoclen)
	uint64_t icv_data_1 = read_from_memory_tx(icv_offset1);
    uint64_t icv_data_2 = read_from_memory_tx(icv_offset2);

    // Store icv_data_1 and icv_data_2 into the scatterlist at offset (cryptlen + assoclen)
    unsigned int icv_sg_offset = cryptlen + req->assoclen;
    if (sg && icv_sg_offset + 2 * sizeof(uint64_t) <= sg->length) {
        memcpy(sg_data + icv_sg_offset, &icv_data_1, sizeof(uint64_t));
        memcpy(sg_data + icv_sg_offset + sizeof(uint64_t), &icv_data_2, sizeof(uint64_t));
    } else {
        pr_notice("Warning: Scatterlist buffer too small for ICV data, truncating copy.\n");
    }

    write_to_memory_DR(mapped_base_DR_tx, DATA_READY_tx + 0x8, 00);
    req->src = req->dst;

    return ret;
}

int read_rx_payload_FPGA(struct aead_request *req) {
    int ret = 0;
    unsigned int offset = 0x100;
    unsigned int sg_offset = req->assoclen;
    unsigned int processed = 0;
    uint64_t temp_buffer = 0;

    unsigned int cryptlen = req->cryptlen;
    unsigned int icv_offset = (cryptlen + 0xF) & ~0xF; // Align to next 16-byte boundary
    struct scatterlist *sg = req->dst;
    uint8_t *sg_data = sg_virt(sg);

    while (processed < cryptlen && sg) {
        if (sg_offset >= sg->length) {
            sg = sg_next(sg);
            if (!sg) {
                pr_notice("Scatterlist exhausted, stopping further writes.\n");
                break;
            }
            sg_offset = 0;
            sg_data = sg_virt(sg);
        }

        temp_buffer = read_from_memory_rx(BRAM_BASE_rx + offset);

        // Prevent buffer overflow in scatterlist writes
        if (sg_offset + sizeof(uint64_t) <= sg->length) {
            memcpy(sg_data + sg_offset, &temp_buffer, sizeof(uint64_t));
        } else {
            pr_notice("Warning: Scatterlist buffer too small, truncating copy.\n");
            break;
        }

        sg_offset += sizeof(uint64_t);
        offset += sizeof(uint64_t);
        processed += sizeof(uint64_t);
    }

	unsigned int icv_offset1 =BRAM_BASE_rx + 0x100 + icv_offset - 0x10;
	unsigned int icv_offset2 =BRAM_BASE_rx + 0x100 + icv_offset + sizeof(uint64_t) - 0x10;


    // Read two times uint64 from icv_offset to (cryptlen + assoclen)
	uint64_t icv_data_1 = read_from_memory_rx(icv_offset1);
    uint64_t icv_data_2 = read_from_memory_rx(icv_offset2);

    // Store icv_data_1 and icv_data_2 into the scatterlist at offset (cryptlen + assoclen)
    unsigned int icv_sg_offset = cryptlen + req->assoclen - 0x10;

    if (sg && icv_sg_offset + 2 * sizeof(uint64_t) <= sg->length) {
        memcpy(sg_data + icv_sg_offset, &icv_data_1, sizeof(uint64_t));
        memcpy(sg_data + icv_sg_offset + sizeof(uint64_t), &icv_data_2, sizeof(uint64_t));
    } else {
        pr_notice("Warning: Scatterlist buffer too small for ICV data, truncating copy.\n");
    }

    write_to_memory_DR(mapped_base_DR_rx, DATA_READY_rx + 0x8, 00);
    req->src = req->dst;

    return ret;
}



//###############################################################################
//###############################################################################
//###############################################################################





struct hwacc_local {
	int irq;
	unsigned long mem_start;
	unsigned long mem_end;
	void __iomem *base_addr;
};

static irqreturn_t hwacc_irq(int irq, void *lp)
{
	printk("hwacc interrupt\n");
	return IRQ_HANDLED;
}

static int hwacc_probe(struct platform_device *pdev)
{
	struct resource *r_irq; /* Interrupt resources */
	struct resource *r_mem; /* IO mem resources */
	struct device *dev = &pdev->dev;
	struct hwacc_local *lp = NULL;

	int rc = 0;
	dev_info(dev, "Device Tree Probing\n");
	/* Get iospace for the device */
	r_mem = platform_get_resource(pdev, IORESOURCE_MEM, 0);
	if (!r_mem) {
		dev_err(dev, "invalid address\n");
		return -ENODEV;
	}
	lp = (struct hwacc_local *) kmalloc(sizeof(struct hwacc_local), GFP_KERNEL);
	if (!lp) {
		dev_err(dev, "Cound not allocate hwacc device\n");
		return -ENOMEM;
	}
	dev_set_drvdata(dev, lp);
	lp->mem_start = r_mem->start;
	lp->mem_end = r_mem->end;

	if (!request_mem_region(lp->mem_start,
				lp->mem_end - lp->mem_start + 1,
				DRIVER_NAME)) {
		dev_err(dev, "Couldn't lock memory region at %p\n",
			(void *)lp->mem_start);
		rc = -EBUSY;
		goto error1;
	}

	lp->base_addr = ioremap(lp->mem_start, lp->mem_end - lp->mem_start + 1);
	if (!lp->base_addr) {
		dev_err(dev, "hwacc: Could not allocate iomem\n");
		rc = -EIO;
		goto error2;
	}

	/* Get IRQ for the device */
	r_irq = platform_get_resource(pdev, IORESOURCE_IRQ, 0);
	if (!r_irq) {
		dev_info(dev, "no IRQ found\n");
		dev_info(dev, "hwacc at 0x%08x mapped to 0x%08x\n",
			(unsigned int __force)lp->mem_start,
			(unsigned int __force)lp->base_addr);
		return 0;
	}
	lp->irq = r_irq->start;
	rc = request_irq(lp->irq, &hwacc_irq, 0, DRIVER_NAME, lp);
	if (rc) {
		dev_err(dev, "testmodule: Could not allocate interrupt %d.\n",
			lp->irq);
		goto error3;
	}

	dev_info(dev,"hwacc at 0x%08x mapped to 0x%08x, irq=%d\n",
		(unsigned int __force)lp->mem_start,
		(unsigned int __force)lp->base_addr,
		lp->irq);
	return 0;
error3:
	free_irq(lp->irq, lp);
error2:
	release_mem_region(lp->mem_start, lp->mem_end - lp->mem_start + 1);
error1:
	kfree(lp);
	dev_set_drvdata(dev, NULL);
	return rc;
}

static int hwacc_remove(struct platform_device *pdev)
{
	struct device *dev = &pdev->dev;
	struct hwacc_local *lp = dev_get_drvdata(dev);
	free_irq(lp->irq, lp);
	iounmap(lp->base_addr);
	release_mem_region(lp->mem_start, lp->mem_end - lp->mem_start + 1);
	kfree(lp);
	dev_set_drvdata(dev, NULL);
	return 0;
}

#ifdef CONFIG_OF
static struct of_device_id hwacc_of_match[] = {
	{ .compatible = "vendor,hwacc", },
	{ /* end of list */ },
};
MODULE_DEVICE_TABLE(of, hwacc_of_match);
#else
# define hwacc_of_match
#endif


ssize_t egress_thread_add_work(struct aead_request *req, bool encrypt, bool decrypt)
{
	struct kritis3m_queue_element *new_element;

    if (!req) {
        pr_err("ERROR: `req` is NULL in egress_thread_add_work\n");
        return -EINVAL;
    }

    if (!req->iv) {
        pr_err("ERROR: `req->iv` is NULL in egress_thread_add_work\n");
        return -EINVAL;
    }


	/* lock thread to add element to the work list */
	spin_lock(&egress_driver->lock);

	new_element = kmalloc(sizeof(struct kritis3m_queue_element), GFP_KERNEL);
    if (!new_element) {
        spin_unlock(&egress_driver->lock);
        return -ENOMEM;
    }

	new_element->req = req;
    new_element->encrypt = encrypt;
    new_element->decrypt = decrypt;

	/* Add the new element to the work list */
    list_add_tail(&new_element->list, &WORK_LIST);
    egress_driver->work_cnt++;

    /* Unlock thread and proceed with the main routine */
    spin_unlock(&egress_driver->lock);

    /* Wake up the egress thread if it is currently sleeping */
    wake_up_interruptible(&egress_driver->waitq);


	return 0;

DATA_ALLOC_ERROR:
	kfree(new_element);
	return -ENOMEM;
}
EXPORT_SYMBOL(egress_thread_add_work);


ssize_t egress_thread_init_rx(char *key, int key_len)
{

	init_rx_key_FPGA(key, key_len);

	return 0;
}
EXPORT_SYMBOL(egress_thread_init_rx);


ssize_t egress_thread_init_tx(char *key, int key_len)
{
	init_tx_key_FPGA(key, key_len);

	return 0;
}
EXPORT_SYMBOL(egress_thread_init_tx);


static struct platform_driver hwacc_driver = {
	.driver = {
		.name = DRIVER_NAME,
		.owner = THIS_MODULE,
		.of_match_table	= hwacc_of_match,
	},
	.probe		= hwacc_probe,
	.remove		= hwacc_remove,
};

static inline int kritis3m_work_pending(void)
{
	struct list_head *work_item, *next;

	/* any work items assigned to this thread? */
	if (list_empty(&WORK_LIST)) {
		printk("[ INFO ] currently 0 elements in work list\n");
		return 0;
	}

	int num_of_entries = 0;
	/* any work item has pending work to do? */
	list_for_each_safe(work_item, next, &WORK_LIST) {
		num_of_entries++;
	}

	printk("[ INFO ] currently %d elements in work list\n", num_of_entries);
	return (num_of_entries ? 1 : 0);
}

static inline void kritis3m_thread_sleep(void)
{
	printk("[ INFO ] egress_driver thread now going to sleep\n");
		
	/* put egress_driver thread to sleep until work count is incremented */
	wait_event_interruptible(egress_driver->waitq, (egress_driver->work_cnt != 0));
}


static size_t readback_work_item(struct kritis3m_queue_element *work_item)
{
	ssize_t rv = 0;

	if (work_item->encrypt==true)
	{
		read_tx_payload_FPGA(work_item->req);
		write_to_memory_DR(mapped_base_DR_tx, DATA_READY_tx + 0x120, 0x00000001);
	}
	if (work_item->decrypt==true)
	{
		read_rx_payload_FPGA(work_item->req);
		write_to_memory_DR(mapped_base_DR_rx, DATA_READY_rx + 0x120, 0x00000001);
	}

	return rv;
}

static size_t transmit_work_item(struct kritis3m_queue_element *work_item)
{

	ssize_t rv = 0;

	if (work_item->encrypt==true)
	{
		init_tx_IV_FPGA(work_item->req);

		write_tx_associateddata_FPGA(work_item->req);

		write_tx_payload_FPGA(work_item->req);
	}
	if (work_item->decrypt==true)
	{
		init_rx_IV_FPGA(work_item->req);

		write_rx_associateddata_FPGA(work_item->req);

		write_rx_payload_FPGA(work_item->req);
	}
	
	return rv;
}



static int egress_thread_main(void *thread_nr)
{
	struct list_head *iterator, *next;
	struct kritis3m_queue_element *work_item;

	while (!kthread_should_stop()) 
	{
		/* lock thread to add element to the work list */
		spin_lock(&egress_driver->lock);

		if (!kritis3m_work_pending()) 
		{
			spin_unlock(&egress_driver->lock);
			kritis3m_thread_sleep();
			spin_lock(&egress_driver->lock);
		}

		list_for_each_safe(iterator, next, &WORK_LIST) 
		{
			/* execute DMA transfer of data */
			work_item = list_entry(iterator, struct kritis3m_queue_element, list);

			spin_unlock(&egress_driver->lock);

			ssize_t rv = transmit_work_item(work_item);
			if (rv < 0) goto DMA_TRANSMIT_ERR;

			wait_for_crypting(work_item);

			rv = readback_work_item(work_item);
			if(rv < 0) goto DMA_TRANSMIT_ERR;

			int err=0;
			work_item->req->base.complete(&work_item->req->base, err);
			if(err < 0) goto DMA_TRANSMIT_ERR;

			/* delete current element from work list */
			printk("[ INFO ] removing work element from list\n");
			spin_lock(&egress_driver->lock);
			list_del(&work_item->list);
			egress_driver->work_cnt--;


			/* free allocated memory of the work item */
			kfree(work_item);
		}

		/* unlock thread after processing work items */
		spin_unlock(&egress_driver->lock);
	}

	//return 0;
	return -EINPROGRESS;

DMA_TRANSMIT_ERR:
	printk(KERN_ERR "DMA transmission unsuccessful\n");
	return -1;
}

static int __init hwacc_init(void)
{
	printk("file_access - Loading kritis3m_egress_thread\n");


	/* allocate driver struct and populate the associated paramteters */
	egress_driver =	kzalloc(sizeof(struct kritis3m_egress_queue), GFP_KERNEL);
	if (!egress_driver)
		return -ENOMEM;

	/* pass name to kernel thread */
	egress_driver->ID = thread_ID;

	/* initialize thread lock */
	spin_lock_init(&egress_driver->lock);

	/* initialize working list for the egress driver */
	egress_driver->work_cnt = 0;

	/* initialize wait queue head*/
	init_waitqueue_head(&egress_driver->waitq);

	init_rx_BRAM_FPGA();

	init_tx_BRAM_FPGA();

	init_crypting_irq();

	/* initial kernel thread to process egress queue */
	egress_driver->egress_kthread = kthread_create(egress_thread_main, &thread_ID, "egress_kthread");
	if (egress_driver->egress_kthread != NULL) {
		/* Let's start the thread */
		wake_up_process(egress_driver->egress_kthread);
		printk("egress_kthread -- Thread was created and is running now!\n");
	} else {
		printk("egress_kthread -- Thread could not be created!\n");
		goto THP_ERROR;
	}

	return 0;


THP_ERROR:
	filp_close(egress_driver->filp_write, NULL);
	filp_close(egress_driver->filp_read, NULL);
FILP_ERROR:
	return -1;
}


static void __exit hwacc_exit(void)
{
	printk("file_access - Removing kritis3m_egress_thread\n");

	kthread_stop(egress_driver->egress_kthread);

	if (!IS_ERR(egress_driver->filp_write)) 
	{
		filp_close(egress_driver->filp_write, NULL);
		filp_close(egress_driver->filp_read, NULL);
	}

	kfree(egress_driver);
}

module_init(hwacc_init);

