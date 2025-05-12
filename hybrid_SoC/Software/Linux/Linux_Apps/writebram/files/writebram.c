/*
* Copyright (C) 2013-2022  Xilinx, Inc.  All rights reserved.
* Copyright (c) 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
*
* Permission is hereby granted, free of charge, to any person
* obtaining a copy of this software and associated documentation
* files (the "Software"), to deal in the Software without restriction,
* including without limitation the rights to use, copy, modify, merge,
* publish, distribute, sublicense, and/or sell copies of the Software,
* and to permit persons to whom the Software is furnished to do so,
* subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included
* in all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
* IN NO EVENT SHALL XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
* CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in this
* Software without prior written authorization from Xilinx.
*
*/


#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <stdint.h>
#include <sys/types.h>
#include <sys/stat.h>

#define PAGE_SIZE 4096
#define DATA_READY_tx 0xA0020000

// Function to write to memory
void write_to_memory(off_t address, uint64_t value) {
    int fd = open("/dev/mem", O_RDWR | O_SYNC);
    if (fd == -1) {
        perror("Error opening /dev/mem");
        exit(EXIT_FAILURE);
    }

    // Align the address to the page size
    off_t page_base = address & ~(PAGE_SIZE - 1);
    off_t page_offset = address - page_base;

    // Map the memory
    void *mapped_base = mmap(NULL, PAGE_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, page_base);
    if (mapped_base == MAP_FAILED) {
        perror("Error mapping memory");
        close(fd);
        exit(EXIT_FAILURE);
    }

    // Write the value
    volatile uint64_t *mapped_address = (volatile uint64_t *)((char *)mapped_base + page_offset);
    *mapped_address = value;

    // Clean up
    if (munmap(mapped_base, PAGE_SIZE) == -1) {
        perror("Error unmapping memory");
    }
    close(fd);
}

int main() {
    // Key 1
    write_to_memory(0xa0000010, 0x1111111111111111);
    write_to_memory(0xa0000018, 0x1111111111111111);

    // Key 2
    write_to_memory(0xa0000020, 0x1111111111111111);
    write_to_memory(0xa0000028, 0x1111111111111111);

    // IV and size
    write_to_memory(0xa0000030, 0x0100a8488b508696);
    write_to_memory(0xa0000038, 0x001c004e6d000000);

    // AAD 1
    write_to_memory(0xa0000040, 0x8696160000003333);
    write_to_memory(0xa0000048, 0x002ce588a8488b50);

    // AAD 2
    write_to_memory(0xa0000050, 0x8b5086966d000000);
    write_to_memory(0xa0000058, 0x000000000100a848);

    // Userdata 1
    write_to_memory(0xa0000100, 0x240000000060dd86);
    write_to_memory(0xa0000108, 0x0000000000000100);

    // Userdata 2
    write_to_memory(0xa0000110, 0x0000000000000000);
    write_to_memory(0xa0000118, 0x0000000002ff0000);

    // Userdata 3
    write_to_memory(0xa0000120, 0x0000000000000000);
    write_to_memory(0xa0000128, 0x00000205003a1600);

    // Userdata 4
    write_to_memory(0xa0000130, 0x00005726008f0001);
    write_to_memory(0xa0000138, 0x02ff000000040100);

    // Userdata 5
    write_to_memory(0xa0000140, 0x0000000000000000);
    write_to_memory(0xa0000148, 0x0000a8488bff0100);

    // Ready flag
    write_to_memory(DATA_READY_tx+8, 0x1);

    printf("Memory write complete.\n");
    return 0;
}
