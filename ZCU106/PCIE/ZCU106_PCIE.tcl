
################################################################
# This is a generated script based on design: design_1
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2023.2
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   if { [string compare $scripts_vivado_version $current_vivado_version] > 0 } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2042 -severity "ERROR" " This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Sourcing the script failed since it was created with a future version of Vivado."}

   } else {
     catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   }

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source design_1_script.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xczu7ev-ffvc1156-2-e
   set_property BOARD_PART xilinx.com:zcu106:part0:2.6 [current_project]
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name design_1

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_gid_msg -ssname BD::TCL -id 2001 -severity "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_gid_msg -ssname BD::TCL -id 2002 -severity "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_gid_msg -ssname BD::TCL -id 2003 -severity "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_gid_msg -ssname BD::TCL -id 2004 -severity "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_gid_msg -ssname BD::TCL -id 2005 -severity "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_gid_msg -ssname BD::TCL -id 2006 -severity "ERROR" $errMsg}
   return $nRet
}

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
xilinx.com:ip:xdma:4.1\
xilinx.com:ip:util_ds_buf:2.2\
xilinx.com:ip:axi_bram_ctrl:4.1\
xilinx.com:ip:blk_mem_gen:8.4\
xilinx.com:ip:ila:6.2\
"

   set list_ips_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2011 -severity "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2012 -severity "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

if { $bCheckIPsPassed != 1 } {
  common::send_gid_msg -ssname BD::TCL -id 2023 -severity "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################



# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set pci_express_x1 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie_7x_mgt_rtl:1.0 pci_express_x1 ]

  set pcie_refclk [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 pcie_refclk ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {100000000} \
   ] $pcie_refclk


  # Create ports
  set pcie_perstn [ create_bd_port -dir I -type rst pcie_perstn ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_LOW} \
 ] $pcie_perstn

  # Create instance: xdma_0, and set properties
  set xdma_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xdma:4.1 xdma_0 ]
  set_property -dict [list \
    CONFIG.PCIE_BOARD_INTERFACE {pci_express_x1} \
    CONFIG.SYS_RST_N_BOARD_INTERFACE {pcie_perstn} \
    CONFIG.axist_bypass_en {true} \
    CONFIG.axist_bypass_size {1} \
    CONFIG.cfg_mgmt_if {false} \
    CONFIG.pl_link_cap_max_link_speed {5.0_GT/s} \
    CONFIG.xdma_axi_intf_mm {AXI_Memory_Mapped} \
    CONFIG.xdma_rnum_chnl {4} \
    CONFIG.xdma_sts_ports {true} \
    CONFIG.xdma_wnum_chnl {4} \
  ] $xdma_0


  # Create instance: util_ds_buf, and set properties
  set util_ds_buf [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:2.2 util_ds_buf ]
  set_property -dict [list \
    CONFIG.DIFF_CLK_IN_BOARD_INTERFACE {pcie_refclk} \
    CONFIG.USE_BOARD_FLOW {true} \
  ] $util_ds_buf


  # Create instance: axi_bram_ctrl_0, and set properties
  set axi_bram_ctrl_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_0 ]

  # Create instance: blk_mem_gen_0, and set properties
  set blk_mem_gen_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 blk_mem_gen_0 ]
  set_property -dict [list \
    CONFIG.Enable_B {Use_ENB_Pin} \
    CONFIG.Memory_Type {True_Dual_Port_RAM} \
    CONFIG.Port_B_Clock {100} \
    CONFIG.Port_B_Enable_Rate {100} \
    CONFIG.Port_B_Write_Rate {50} \
    CONFIG.Use_RSTB_Pin {true} \
  ] $blk_mem_gen_0


  # Create instance: axi_interconnect_0, and set properties
  set axi_interconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0 ]
  set_property -dict [list \
    CONFIG.NUM_MI {2} \
    CONFIG.NUM_SI {2} \
  ] $axi_interconnect_0


  # Create instance: axi_bram_ctrl_2, and set properties
  set axi_bram_ctrl_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_2 ]

  # Create instance: blk_mem_gen_2, and set properties
  set blk_mem_gen_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 blk_mem_gen_2 ]
  set_property -dict [list \
    CONFIG.Enable_B {Use_ENB_Pin} \
    CONFIG.Memory_Type {True_Dual_Port_RAM} \
    CONFIG.Port_B_Clock {100} \
    CONFIG.Port_B_Enable_Rate {100} \
    CONFIG.Port_B_Write_Rate {50} \
    CONFIG.Use_RSTB_Pin {true} \
  ] $blk_mem_gen_2


  # Create instance: ila_0, and set properties
  set ila_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.2 ila_0 ]

  # Create instance: ila_1, and set properties
  set ila_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.2 ila_1 ]

  # Create instance: ila_2, and set properties
  set ila_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.2 ila_2 ]
  set_property -dict [list \
    CONFIG.C_MONITOR_TYPE {Native} \
    CONFIG.C_NUM_OF_PROBES {8} \
    CONFIG.C_PROBE0_WIDTH {8} \
    CONFIG.C_PROBE1_WIDTH {8} \
    CONFIG.C_PROBE2_WIDTH {8} \
    CONFIG.C_PROBE3_WIDTH {8} \
    CONFIG.C_PROBE4_WIDTH {8} \
    CONFIG.C_PROBE5_WIDTH {8} \
    CONFIG.C_PROBE6_WIDTH {8} \
    CONFIG.C_PROBE7_WIDTH {8} \
  ] $ila_2


  # Create interface connections
  connect_bd_intf_net -intf_net S01_AXI_1 [get_bd_intf_pins axi_interconnect_0/S01_AXI] [get_bd_intf_pins xdma_0/M_AXI_BYPASS]
  connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTA [get_bd_intf_pins blk_mem_gen_0/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTB [get_bd_intf_pins blk_mem_gen_0/BRAM_PORTB] [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_bram_ctrl_2_BRAM_PORTA [get_bd_intf_pins blk_mem_gen_2/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_2/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_2_BRAM_PORTB [get_bd_intf_pins blk_mem_gen_2/BRAM_PORTB] [get_bd_intf_pins axi_bram_ctrl_2/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI [get_bd_intf_pins axi_interconnect_0/M00_AXI] [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]
connect_bd_intf_net -intf_net [get_bd_intf_nets axi_interconnect_0_M00_AXI] [get_bd_intf_pins axi_interconnect_0/M00_AXI] [get_bd_intf_pins ila_0/SLOT_0_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M01_AXI [get_bd_intf_pins axi_interconnect_0/M01_AXI] [get_bd_intf_pins axi_bram_ctrl_2/S_AXI]
connect_bd_intf_net -intf_net [get_bd_intf_nets axi_interconnect_0_M01_AXI] [get_bd_intf_pins axi_interconnect_0/M01_AXI] [get_bd_intf_pins ila_1/SLOT_0_AXI]
  connect_bd_intf_net -intf_net pcie_refclk_1 [get_bd_intf_ports pcie_refclk] [get_bd_intf_pins util_ds_buf/CLK_IN_D]
  connect_bd_intf_net -intf_net xdma_0_M_AXI [get_bd_intf_pins xdma_0/M_AXI] [get_bd_intf_pins axi_interconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net xdma_0_pcie_mgt [get_bd_intf_ports pci_express_x1] [get_bd_intf_pins xdma_0/pcie_mgt]

  # Create port connections
  connect_bd_net -net ACLK_1 [get_bd_pins xdma_0/axi_aclk] [get_bd_pins axi_bram_ctrl_0/s_axi_aclk] [get_bd_pins axi_interconnect_0/ACLK] [get_bd_pins axi_interconnect_0/S00_ACLK] [get_bd_pins axi_interconnect_0/M00_ACLK] [get_bd_pins axi_interconnect_0/M01_ACLK] [get_bd_pins axi_interconnect_0/S01_ACLK] [get_bd_pins axi_bram_ctrl_2/s_axi_aclk] [get_bd_pins ila_0/clk] [get_bd_pins ila_1/clk] [get_bd_pins ila_2/clk]
  connect_bd_net -net pcie_perstn_1 [get_bd_ports pcie_perstn] [get_bd_pins xdma_0/sys_rst_n]
  connect_bd_net -net util_ds_buf_IBUF_DS_ODIV2 [get_bd_pins util_ds_buf/IBUF_DS_ODIV2] [get_bd_pins xdma_0/sys_clk]
  connect_bd_net -net util_ds_buf_IBUF_OUT [get_bd_pins util_ds_buf/IBUF_OUT] [get_bd_pins xdma_0/sys_clk_gt]
  connect_bd_net -net xdma_0_axi_aresetn [get_bd_pins xdma_0/axi_aresetn] [get_bd_pins axi_bram_ctrl_2/s_axi_aresetn] [get_bd_pins axi_interconnect_0/ARESETN] [get_bd_pins axi_interconnect_0/S00_ARESETN] [get_bd_pins axi_interconnect_0/M01_ARESETN] [get_bd_pins axi_interconnect_0/M00_ARESETN] [get_bd_pins axi_interconnect_0/S01_ARESETN] [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn]
  connect_bd_net -net xdma_0_c2h_sts_0 [get_bd_pins xdma_0/c2h_sts_0] [get_bd_pins ila_2/probe0]
  connect_bd_net -net xdma_0_c2h_sts_1 [get_bd_pins xdma_0/c2h_sts_1] [get_bd_pins ila_2/probe1]
  connect_bd_net -net xdma_0_c2h_sts_2 [get_bd_pins xdma_0/c2h_sts_2] [get_bd_pins ila_2/probe2]
  connect_bd_net -net xdma_0_c2h_sts_3 [get_bd_pins xdma_0/c2h_sts_3] [get_bd_pins ila_2/probe3]
  connect_bd_net -net xdma_0_h2c_sts_0 [get_bd_pins xdma_0/h2c_sts_0] [get_bd_pins ila_2/probe4]
  connect_bd_net -net xdma_0_h2c_sts_1 [get_bd_pins xdma_0/h2c_sts_1] [get_bd_pins ila_2/probe5]
  connect_bd_net -net xdma_0_h2c_sts_2 [get_bd_pins xdma_0/h2c_sts_2] [get_bd_pins ila_2/probe6]
  connect_bd_net -net xdma_0_h2c_sts_3 [get_bd_pins xdma_0/h2c_sts_3] [get_bd_pins ila_2/probe7]

  # Create address segments
  assign_bd_address -offset 0x00000000 -range 0x00008000 -target_address_space [get_bd_addr_spaces xdma_0/M_AXI] [get_bd_addr_segs axi_bram_ctrl_0/S_AXI/Mem0] -force
  assign_bd_address -offset 0xE0000000 -range 0x00001000 -target_address_space [get_bd_addr_spaces xdma_0/M_AXI_BYPASS] [get_bd_addr_segs axi_bram_ctrl_2/S_AXI/Mem0] -force

  # Exclude Address Segments
  exclude_bd_addr_seg -offset 0xE0000000 -range 0x00001000 -target_address_space [get_bd_addr_spaces xdma_0/M_AXI] [get_bd_addr_segs axi_bram_ctrl_2/S_AXI/Mem0]
  exclude_bd_addr_seg -offset 0x00000000 -range 0x00008000 -target_address_space [get_bd_addr_spaces xdma_0/M_AXI_BYPASS] [get_bd_addr_segs axi_bram_ctrl_0/S_AXI/Mem0]


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


