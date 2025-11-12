## ========== CLOCK (100 MHz) ==========
set_property PACKAGE_PIN W5 [get_ports CLK100MHZ]
set_property IOSTANDARD LVCMOS33 [get_ports CLK100MHZ]
create_clock -add -name sys_clk_pin -period 10.000 -waveform {0 5} [get_ports CLK100MHZ]

## ========== SWITCHES ==========
# We use SW[7:0], but map all 16 for convenience
set_property PACKAGE_PIN V17 [get_ports {SW[0]}]  ; set_property IOSTANDARD LVCMOS33 [get_ports {SW[0]}]
set_property PACKAGE_PIN V16 [get_ports {SW[1]}]  ; set_property IOSTANDARD LVCMOS33 [get_ports {SW[1]}]
set_property PACKAGE_PIN W16 [get_ports {SW[2]}]  ; set_property IOSTANDARD LVCMOS33 [get_ports {SW[2]}]
set_property PACKAGE_PIN W17 [get_ports {SW[3]}]  ; set_property IOSTANDARD LVCMOS33 [get_ports {SW[3]}]
set_property PACKAGE_PIN W15 [get_ports {SW[4]}]  ; set_property IOSTANDARD LVCMOS33 [get_ports {SW[4]}]
set_property PACKAGE_PIN V15 [get_ports {SW[5]}]  ; set_property IOSTANDARD LVCMOS33 [get_ports {SW[5]}]
set_property PACKAGE_PIN W14 [get_ports {SW[6]}]  ; set_property IOSTANDARD LVCMOS33 [get_ports {SW[6]}]
set_property PACKAGE_PIN W13 [get_ports {SW[7]}]  ; set_property IOSTANDARD LVCMOS33 [get_ports {SW[7]}]
set_property PACKAGE_PIN V2  [get_ports {SW[8]}]  ; set_property IOSTANDARD LVCMOS33 [get_ports {SW[8]}]
set_property PACKAGE_PIN T3  [get_ports {SW[9]}]  ; set_property IOSTANDARD LVCMOS33 [get_ports {SW[9]}]
set_property PACKAGE_PIN T2  [get_ports {SW[10]}] ; set_property IOSTANDARD LVCMOS33 [get_ports {SW[10]}]
set_property PACKAGE_PIN R3  [get_ports {SW[11]}] ; set_property IOSTANDARD LVCMOS33 [get_ports {SW[11]}]
set_property PACKAGE_PIN W2  [get_ports {SW[12]}] ; set_property IOSTANDARD LVCMOS33 [get_ports {SW[12]}]
set_property PACKAGE_PIN U1  [get_ports {SW[13]}] ; set_property IOSTANDARD LVCMOS33 [get_ports {SW[13]}]
set_property PACKAGE_PIN T1  [get_ports {SW[14]}] ; set_property IOSTANDARD LVCMOS33 [get_ports {SW[14]}]
set_property PACKAGE_PIN R2  [get_ports {SW[15]}] ; set_property IOSTANDARD LVCMOS33 [get_ports {SW[15]}]

## ========== BUTTON (Left) ==========
set_property PACKAGE_PIN W19 [get_ports btnL]
set_property IOSTANDARD LVCMOS33 [get_ports btnL]

## ========== SEVEN-SEGMENT DISPLAY (common-anode) ==========
# segments a..g
set_property PACKAGE_PIN W7  [get_ports CA] ; set_property IOSTANDARD LVCMOS33 [get_ports CA]
set_property PACKAGE_PIN W6  [get_ports CB] ; set_property IOSTANDARD LVCMOS33 [get_ports CB]
set_property PACKAGE_PIN U8  [get_ports CC] ; set_property IOSTANDARD LVCMOS33 [get_ports CC]
set_property PACKAGE_PIN V8  [get_ports CD] ; set_property IOSTANDARD LVCMOS33 [get_ports CD]
set_property PACKAGE_PIN U5  [get_ports CE] ; set_property IOSTANDARD LVCMOS33 [get_ports CE]
set_property PACKAGE_PIN V5  [get_ports CF] ; set_property IOSTANDARD LVCMOS33 [get_ports CF]
set_property PACKAGE_PIN U7  [get_ports CG] ; set_property IOSTANDARD LVCMOS33 [get_ports CG]
# decimal point
set_property PACKAGE_PIN V7  [get_ports DP] ; set_property IOSTANDARD LVCMOS33 [get_ports DP]
# anodes (AN3..AN0 = left..right)
set_property PACKAGE_PIN W4  [get_ports {AN[3]}] ; set_property IOSTANDARD LVCMOS33 [get_ports {AN[3]}]
set_property PACKAGE_PIN V4  [get_ports {AN[2]}] ; set_property IOSTANDARD LVCMOS33 [get_ports {AN[2]}]
set_property PACKAGE_PIN U4  [get_ports {AN[1]}] ; set_property IOSTANDARD LVCMOS33 [get_ports {AN[1]}]
set_property PACKAGE_PIN U2  [get_ports {AN[0]}] ; set_property IOSTANDARD LVCMOS33 [get_ports {AN[0]}]

## ========== USB-UART (FPGA ? PC) ==========
# RsTx (A18) is the Basys-3 FTDI TX pin going to the PC
set_property PACKAGE_PIN A18 [get_ports uart_txd]
set_property IOSTANDARD LVCMOS33 [get_ports uart_txd]
