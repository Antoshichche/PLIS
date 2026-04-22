set_property -dict { PACKAGE_PIN L16   IOSTANDARD LVCMOS33 } [get_ports { clk }] 
create_clock -add -name sys_clk_pin -period 8.00 -waveform {0 4} [get_ports { clk }]


set_property -dict { PACKAGE_PIN R18   IOSTANDARD LVCMOS33 } [get_ports { reset }] 
set_property -dict { PACKAGE_PIN P16   IOSTANDARD LVCMOS33 } [get_ports { start }] 

set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports { led_o }] 
#set_property -dict { PACKAGE_PIN M15   IOSTANDARD LVCMOS33 } [get_ports { R_led_o }]; 

set_property -dict {PACKAGE_PIN U14 IOSTANDARD LVCMOS33} [get_ports half_clk]
set_property -dict {PACKAGE_PIN L17 IOSTANDARD LVCMOS33} [get_ports inv_clk]
set_property -dict {PACKAGE_PIN P18 IOSTANDARD LVCMOS33} [get_ports brst_o]
#set_property -dict {PACKAGE_PIN Y13 IOSTANDARD LVCMOS33} [get_ports st]