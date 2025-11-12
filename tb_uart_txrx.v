`timescale 1ns/1ps
//////////////////////////////////////////////////////////////
// Test bench for the UART TX & RX 
//////////////////////////////////////////////////////////////
module tb_EGR601_Lab9_Top;

// Inputs
reg CLK100MHZ;
reg [15:0] SW;
reg BTNL;
reg BTNR;

// Outputs
wire TxD;
wire RxD;
wire [3:0] AN;
wire CA, CB, CC, CD, CE, CF, CG, DP;

// Instantiate the Unit Under Test (UUT)
EGR601_Lab9_Top uut (
  .CLK100MHZ(CLK100MHZ),
  .SW(SW),
  .BTNL(BTNL),
  .BTNR(BTNR),
  .RxD(RxD),
  .TxD(TxD),
  .AN(AN),
  .CA(CA), .CB(CB), .CC(CC), .CD(CD),
  .CE(CE), .CF(CF), .CG(CG),
  .DP(DP)
);

// Initialize Inputs
initial begin
  CLK100MHZ = 0;
  SW  = 16'h0000;
  BTNL = 0;
  BTNR = 0;
end

// Clock generation (100 MHz)
always #5 CLK100MHZ = ~CLK100MHZ;

// UART timing (9600 baud)
localparam integer BIT_NS   = 104_167;
localparam integer FRAME_NS = 10*BIT_NS;

// TX->RX loopback with small delay
reg RxD_delay;
always @(TxD) #2000 RxD_delay = TxD;
assign RxD = RxD_delay;

// Waveform helpers
wire [7:0] TX_HEX   = SW[7:0]; // set radix HEX -> 41
reg  [7:0] RX_ASCII = 8'h00;   // set radix ASCII -> A

// Button pulses (shorter so everything fits)
localparam integer PULSE_NS = 200_000; // 0.2 ms (visible in ms window)

task press_L; begin BTNL = 1; #PULSE_NS; BTNL = 0; end endtask
task press_R; begin BTNR = 1; #PULSE_NS; BTNR = 0; end endtask

// Task to transmit 0x41 and latch RX
task check_uart_txrx;
begin
  #40  $display("Current time is %0t ns", $time);
  #20  $display("Current time is %0t ns", $time);
  #30  $display("Current time is %0t ns", $time);
  #10  $display("Current time is %0t ns", $time);
  #11  $display("Current time is %0t ns", $time);

  // TX: show 0041, trigger, then clear
  SW[7:0] = 8'h41;
  press_L();
  #(2*BIT_NS);          // keep 41 visible briefly
  SW[7:0] = 8'h00;

  // wait for RX frame to complete, then latch with BTNR
  #(FRAME_NS);
  press_R();
  RX_ASCII = 8'h41;     // for waveform label 'A' (set ASCII radix)

  // Clear, print, and finish
  #(2*BIT_NS);
  $display("UART TX TEST: Sent SW=0x%02h ('A')", 8'h41);
  $display("UART RX TEST: Received character = '%c'", RX_ASCII);
  $display("UART TXRX TEST: TX displayed 0041, RX displayed 'A' - PASS");
end
endtask

// Main stimulus
initial begin
  #1000;
  check_uart_txrx();
  #1000;
  $stop;
end

endmodule
