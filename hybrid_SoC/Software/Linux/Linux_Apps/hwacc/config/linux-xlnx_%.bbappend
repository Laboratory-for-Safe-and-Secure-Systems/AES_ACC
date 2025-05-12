FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"


SRC_URI:append = " file://bsp.cfg"
KERNEL_FEATURES:append = " bsp.cfg"
SRC_URI += "file://user_2025-02-10-08-13-00.cfg \
            file://user_2025-03-04-15-06-00.cfg \
            file://user_2025-03-06-07-12-00.cfg \
            file://user_2025-03-06-07-48-00.cfg \
            "

RDEPENDS:${PN} += "kernel-module-hwacc"

