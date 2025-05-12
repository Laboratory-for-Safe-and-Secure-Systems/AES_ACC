
NET_Interface="eth0"

DESTINATION_MAC_LAPTOP="e8:80:88:1f:f1:0c"        # Laptop ThinkPad
DESTINATION_MAC_FPGA="D2:04:31:B0:0A:02"            # Xilinx Zynq CZU106
   
SAK_LAPTOP="01 1111111111111111111111111111111111111111111111111111111111111111" # Laptop ThinkPad
SAK_FPGA="03 3333333333333333333333333333333333333333333333333333333333333333"   # Xilinx FPGA

IP_Addr_LAPTOP="10.10.1.1/24"                       # Laptop ThinkPad
IP_Addr_FPGA="10.10.1.3/24"                         # Xilinx FPGA

ip link delete macsec0 
 
ip link add link $NET_Interface macsec0 type macsec cipher gcm-aes-256 encrypt off

ip macsec add macsec0 tx sa 0 pn 100 on key $SAK_LAPTOP

ip macsec add macsec0 rx address $DESTINATION_MAC_LAPTOP port 1
ip macsec add macsec0 rx address $DESTINATION_MAC_LAPTOP port 1 sa 0 pn 100 on key $SAK_LAPTOP

ip link set dev macsec0 up
 
ip addr add $IP_Addr_FPGA dev macsec0

