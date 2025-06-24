## Zedbaord Source Clock
set_property PACKAGE_PIN Y9 [get_ports clk_100mhz]
set_property IOSTANDARD LVCMOS33 [get_ports clk_100mhz]

## Reset Button
set_property PACKAGE_PIN P16 [get_ports reset]
set_property IOSTANDARD LVCMOS33 [get_ports reset]

## VGA Sync signals
set_property PACKAGE_PIN AA19 [get_ports h_sync]
set_property IOSTANDARD LVCMOS33 [get_ports h_sync]

set_property PACKAGE_PIN Y19 [get_ports v_sync]
set_property IOSTANDARD LVCMOS33 [get_ports v_sync]

## VGA RGB Outputs
set_property PACKAGE_PIN V20  [get_ports {red[0]}];  # "VGA-R1"
set_property PACKAGE_PIN U20  [get_ports {red[1]}];  # "VGA-R2"
set_property PACKAGE_PIN V19  [get_ports {red[2]}];  # "VGA-R3"
set_property PACKAGE_PIN V18  [get_ports {red[3]}];  # "VGA-R4"
set_property IOSTANDARD LVCMOS33 [get_ports {red[*]}]

set_property PACKAGE_PIN AB22 [get_ports {green[0]}];  # "VGA-G1"
set_property PACKAGE_PIN AA22 [get_ports {green[1]}];  # "VGA-G2"
set_property PACKAGE_PIN AB21 [get_ports {green[2]}];  # "VGA-G3"
set_property PACKAGE_PIN AA21 [get_ports {green[3]}];  # "VGA-G4"
set_property IOSTANDARD LVCMOS33 [get_ports {green[*]}]


set_property PACKAGE_PIN Y21  [get_ports {blue[0]}];  # "VGA-B1"
set_property PACKAGE_PIN Y20  [get_ports {blue[1]}];  # "VGA-B2"
set_property PACKAGE_PIN AB20 [get_ports {blue[2]}];  # "VGA-B3"
set_property PACKAGE_PIN AB19 [get_ports {blue[3]}];  # "VGA-B4"
set_property IOSTANDARD LVCMOS33 [get_ports {blue[*]}]

## debug led
set_property PACKAGE_PIN T22 [get_ports {led[0]}];  
set_property PACKAGE_PIN T21 [get_ports {led[1]}];
set_property PACKAGE_PIN U22 [get_ports {led[2]}];
set_property PACKAGE_PIN U21 [get_ports {led[3]}];
set_property PACKAGE_PIN V22 [get_ports {led[4]}]; 
set_property IOSTANDARD LVCMOS33 [get_ports {led[*]}]