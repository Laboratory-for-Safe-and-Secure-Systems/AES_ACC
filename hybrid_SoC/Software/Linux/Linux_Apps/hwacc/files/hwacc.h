#ifndef EGRSS_THRT_H
#define EGRSS_THRT_H

//add into linux-xlnx/include/include/linux

#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/fs.h>
#include <linux/spinlock.h>
#include <linux/uaccess.h>
#include <linux/jiffies.h>
#include <linux/file.h>
#include <linux/export.h>
#include <linux/sched.h>
#include <linux/kthread.h>
#include <linux/delay.h>
#include <linux/string.h>
#include <linux/wait.h>

#include <crypto/aead.h>


/* Struct Definitions */
struct kritis3m_egress_queue 
{
    /* thread ID */
    int ID;

    /* thread lock*/
	spinlock_t lock;

    /* kernel task structure associated with thread */
    struct task_struct *egress_kthread;

    /* file pointer to access the xdma character driver write OP */
    struct file *filp_write;

    /* file pointer to access the xdma character driver read OP */
    struct file *filp_read;

    /* thread work list count */
	unsigned int work_cnt;

    /* thread wait queue parameter */
	wait_queue_head_t waitq;

};

struct kritis3m_queue_element
{
    struct list_head list;

    struct aead_request *req;

    bool encrypt;
    bool decrypt;

};

static inline void hwacc_request_set_callback(struct aead_request *req,
					     u32 flags,
					     crypto_completion_t compl,
					     void *data)
{
	req->base.complete = compl;
	req->base.data = data;
	req->base.flags = flags;
}

/* Input API to the egress queue */
ssize_t egress_thread_init_rx(char *key, int key_len);
ssize_t egress_thread_init_tx(char *key, int key_len);


ssize_t egress_thread_add_work(struct aead_request *req, bool encrypt, bool decrypt);



#endif