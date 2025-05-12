# Kernel module build setup
obj-m := hwacc.o

# Additional CFLAGS
MY_CFLAGS += -g -DDEBUG -I $(KERNEL_SRC)/include
ccflags-y += ${MY_CFLAGS}

# Kernel source directory from PetaLinux environment
KERNEL_SRC ?= $(STAGING_KERNEL_DIR)
SRC := $(shell pwd)

# Default target: build the module
all:
	$(MAKE) -C $(KERNEL_SRC) M=$(SRC) modules

# Install the module into the root filesystem
modules_install:
	$(MAKE) -C $(KERNEL_SRC) M=$(SRC) modules_install

# Clean up generated files
clean:
	rm -f *.o *~ core .depend .*.cmd *.ko *.mod.c
	rm -f Module.markers Module.symvers modules.order
	rm -rf .tmp_versions Modules.symvers


