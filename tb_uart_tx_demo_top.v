`timescale 1ns/1ps
//////////////////////////////////////////////////////////////
// Test bench for the UART TX (Lab 9 Part 1)
//////////////////////////////////////////////////////////////
module tb_uart_tx_demo_top;

// Inputs
reg CLK100MHZ;
reg btnL;
reg [15:0] SW;

// Outputs
wire uart_txd;
wire [3:0] AN;
wire CA, CB, CC, CD, CE, CF, CG, DP;

// Instantiate the Unit Under Test (UUT)
uart_tx_demo_top uut (
  .CLK100MHZ(CLK100MHZ),
  .btnL(btnL),
  .SW(SW),
  .uart_txd(uart_txd),
  .AN(AN),
  .CA(CA), .CB(CB), .CC(CC), .CD(CD), .CE(CE), .CF(CF), .CG(CG),
  .DP(DP)
);

// Initialize Inputs
initial begin
  CLK100MHZ = 0;
  btnL      = 0;
  SW        = 16'h0000;
end

// Clock generation (100 MHz)
always #5 CLK100MHZ = ~CLK100MHZ;

// --- UART timing (9600 baud) ---
localparam integer BIT_NS   = 104_167;        // ~104.167 µs per bit
localparam integer FRAME_NS = 10*BIT_NS;      // start + 8 data + stop

// Wider button pulse so it's visible in ms-scale waveform
task press_btnL;
begin
  btnL = 1;
  #10_000;    // 10 µs high (easy to see)
  btnL = 0;
end
endtask

// Task to send 0x41 ('A'), then report SENT
task check_uart_tx;
begin
  #40  $display("Current time is %0t ns", $time);
  #20  $display("Current time is %0t ns", $time);
  #30  $display("Current time is %0t ns", $time);
  #10  $display("Current time is %0t ns", $time);
  #11  $display("Current time is %0t ns", $time);

  // Load, trigger, briefly show 0x41, then clear for a neat waveform
  SW[7:0] = 8'h41;          // ASCII 'A'
  press_btnL();             // visible BTN pulse
  #(2*BIT_NS);              // keep value visible ~2 bit-times
  SW[7:0] = 8'h00;          // clear so it's "ready for next value"

  #(FRAME_NS);              // allow frame to complete
  $display("UART TX TEST: Sent 0x41 ('A') - PASS");
end
endtask

// Main stimulus
initial begin
  #1000;           // settle
  check_uart_tx(); // run the task
  #1000;
  $stop;           // stop simulator (GUI)
end

endmodule
