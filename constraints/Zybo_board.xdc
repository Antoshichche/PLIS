
###Clock signal
#set_property -dict {PACKAGE_PIN L16 IOSTANDARD LVCMOS33} [get_ports clk]

###Switches
#set_property -dict {PACKAGE_PIN G15 IOSTANDARD LVCMOS33} [get_ports {reset}]
#set_property -dict {PACKAGE_PIN P15 IOSTANDARD LVCMOS33} [get_ports start_o]


###LEDs
#set_property -dict {PACKAGE_PIN M14 IOSTANDARD LVCMOS33} [get_ports S_led_o]
#set_property -dict {PACKAGE_PIN M15 IOSTANDARD LVCMOS33} [get_ports R_led_o]

#create_clock -period 8.000 -name clk -waveform {0.000 1.000} -add


# =============================================
# ������������ XDC ��� Lab5 - Zybo Z7 (16-������ counter)
# ��� ����� ����� IOSTANDARD � LOC (��� DRC NST D-1 � UCIO-1)
# =============================================

# ==================== �������� ���� ====================
set_property -dict { PACKAGE_PIN L16 IOSTANDARD LVCMOS33 } [get_ports clk]
create_clock -period 10.000 -name sys_clk -waveform {0.000 4.000} [get_ports clk]

# ==================== ������ ====================
set_property -dict { PACKAGE_PIN R18 IOSTANDARD LVCMOS33 } [get_ports reset]   
set_property -dict { PACKAGE_PIN P16 IOSTANDARD LVCMOS33 } [get_ports start]  

# ==================== ���������� ====================
set_property -dict { PACKAGE_PIN M14 IOSTANDARD LVCMOS33 } [get_ports S_led_o]
set_property -dict { PACKAGE_PIN M15 IOSTANDARD LVCMOS33 } [get_ports R_led_o]

# ==================== ����� (�����) ====================
# set_property -dict { PACKAGE_PIN G14 IOSTANDARD LVCMOS33 } [get_ports brst_o]

# ==================== ������� ������ in_data[15:0] ====================
# set_property -dict { PACKAGE_PIN T15 IOSTANDARD LVCMOS33 } [get_ports {in_data[0]}]
# set_property -dict { PACKAGE_PIN T14 IOSTANDARD LVCMOS33 } [get_ports {in_data[1]}]
# set_property -dict { PACKAGE_PIN R14 IOSTANDARD LVCMOS33 } [get_ports {in_data[2]}]
# set_property -dict { PACKAGE_PIN L14 IOSTANDARD LVCMOS33 } [get_ports {in_data[3]}]
# set_property -dict { PACKAGE_PIN U13 IOSTANDARD LVCMOS33 } [get_ports {in_data[4]}]
# set_property -dict { PACKAGE_PIN V13 IOSTANDARD LVCMOS33 } [get_ports {in_data[5]}]
# set_property -dict { PACKAGE_PIN W14 IOSTANDARD LVCMOS33 } [get_ports {in_data[6]}]
# set_property -dict { PACKAGE_PIN Y14 IOSTANDARD LVCMOS33 } [get_ports {in_data[7]}]
# set_property -dict { PACKAGE_PIN V12 IOSTANDARD LVCMOS33 } [get_ports {in_data[8]}]
# set_property -dict { PACKAGE_PIN W13 IOSTANDARD LVCMOS33 } [get_ports {in_data[9]}]
# set_property -dict { PACKAGE_PIN T12 IOSTANDARD LVCMOS33 } [get_ports {in_data[10]}]
# set_property -dict { PACKAGE_PIN T11 IOSTANDARD LVCMOS33 } [get_ports {in_data[11]}]
# set_property -dict { PACKAGE_PIN U12 IOSTANDARD LVCMOS33 } [get_ports {in_data[12]}]
# set_property -dict { PACKAGE_PIN L15 IOSTANDARD LVCMOS33 } [get_ports {in_data[13]}]
# set_property -dict { PACKAGE_PIN H15 IOSTANDARD LVCMOS33 } [get_ports {in_data[14]}]
# set_property -dict { PACKAGE_PIN K14 IOSTANDARD LVCMOS33 } [get_ports {in_data[15]}]

