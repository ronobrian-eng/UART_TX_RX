// ============================================================================
// EGR 601 - Lab 9 Part I
// UART TX
// ============================================================================

`timescale 1ns/1ps

// --------------------------- Debounce + One-shot ----------------------------
// Module to debounce an asynchronous button input and generate a single-clock pulse
// on the rising edge (press) of the debounced signal.
module btn_sync_oneshot(
  input  wire clk,          // 100 MHz clock
  input  wire btn_async,    // active-high asynchronous pushbutton input
  output wire pulse         // 1-clock cycle pulse on rising edge of debounced button
);
  // Synchronizer: shift register to bring async input into the clock domain
  reg [2:0] sync;
  always @(posedge clk) sync <= {sync[1:0], btn_async};

  // Debounce logic: simple 3-tap majority vote for debounce
  wire deb = (sync[2] & sync[1]) | (sync[1] & sync[0]) | (sync[2] & sync[0]);

  // Delay the debounced signal by one clock cycle
  reg deb_d;
  always @(posedge clk) deb_d <= deb;

  // One-shot pulse generation: rising edge of debounced signal (deb AND NOT deb_d)
  assign pulse = deb & ~deb_d;  // rising-edge one-shot
endmodule

// -------------------------------- Baud tick ---------------------------------
// Module to generate a single-clock tick at the specified baud rate.
module baud_gen #(
  parameter CLK_HZ = 100_000_000, // Input clock frequency in Hz
  parameter BAUD   = 9600         // Baud rate for serial communication
)(
  input  wire clk,
  output reg  tick                // 1-clock pulse, one per bit time
);
  // Calculate the division factor for the counter.
  // DIV = CLK_HZ / BAUD. Add BAUD/2 for rounding.
  // 100e6 / 9600 ? 10417
  localparam integer DIV = (CLK_HZ + BAUD/2) / BAUD;
  
  // Counter to divide the input clock frequency
  reg [15:0] cnt = 16'd0;
  
  always @(posedge clk) begin
    if (cnt == DIV-1) begin
      cnt  <= 16'd0;    // Reset counter
      tick <= 1'b1;     // Generate a tick pulse
    end else begin
      cnt  <= cnt + 1'b1; // Increment counter
      tick <= 1'b0;     // No tick
    end
  end
endmodule

// -------------------------------- UART TX -----------------------------------
// Module to transmit a byte of data using the UART protocol (8-N-1 format).
module uart_tx(
  input  wire        clk,
  input  wire        tick,    // 1 pulse per bit time (from baud_gen)
  input  wire        start,    // 1-clk pulse to start transmit
  input  wire [7:0] data,     // Data to be transmitted
  output reg         txd,      // Transmit Data output (idle high)
  output reg         busy      // High when transmission is in progress
);
  // State machine parameters for the transmission process
  localparam [1:0] ST_IDLE  = 2'd0,  // Waiting for 'start'
                   ST_START = 2'd1,  // Transmitting Start Bit
                   ST_DATA  = 2'd2,  // Transmitting Data Bits
                   ST_STOP  = 2'd3;  // Transmitting Stop Bit

  reg [1:0] state = ST_IDLE; // Current state
  reg [7:0] shifter;         // Shift register for data transmission
  reg [2:0] bit_idx;         // Counter for the 8 data bits (0 to 7)

  // Initialize outputs
  initial begin
    txd  = 1'b1; // TX line idle is high
    busy = 1'b0; // Not busy
  end

  // State machine logic
  always @(posedge clk) begin
    case (state)
      ST_IDLE: begin
        txd  <= 1'b1; // Ensure TX line is high (idle)
        busy <= 1'b0; // Not busy
        if (start) begin // Transition on 'start' pulse
          shifter <= data; // Load data into shift register
          bit_idx <= 3'd0; // Reset bit counter
          busy    <= 1'b1; // Set busy flag
          state   <= ST_START; // Move to start bit state
        end
      end

      ST_START: if (tick) begin // Hold state for one bit time
        txd    <= 1'b0;        // Start bit is always low
        state <= ST_DATA;     // Move to data state
      end

      ST_DATA: if (tick) begin // Hold state for one bit time
        txd     <= shifter[0];           // Transmit the LSB first
        shifter <= {1'b0, shifter[7:1]}; // Shift right
        
        if (bit_idx == 3'd7) state <= ST_STOP; // Last bit transmitted, go to stop bit
        
        bit_idx <= bit_idx + 1'b1; // Increment bit counter
      end

      ST_STOP: if (tick) begin // Hold state for one bit time
        txd    <= 1'b1;        // Stop bit is always high
        state <= ST_IDLE;     // Return to idle state
      end
    endcase
  end
endmodule

// ----------------------------- Hex to 7-segment -----------------------------
// Module to convert a 4-bit hexadecimal nibble into a 7-segment display pattern.
// Bit order = {a,b,c,d,e,f,g}, active-low (0 = ON)
module hex7seg(
  input  wire [3:0] nib, // 4-bit hex input
  output reg  [6:0] seg  // 7-segment output (active-low)
);
  // Combinational logic using a case statement
  always @* begin
    case (nib)
      4'h0: seg = 7'b1000000; // 0
      4'h1: seg = 7'b1111001; // 1
      4'h2: seg = 7'b0100100; // 2
      4'h3: seg = 7'b0110000; // 3
      4'h4: seg = 7'b0011001; // 4
      4'h5: seg = 7'b0010010; // 5
      4'h6: seg = 7'b0000010; // 6
      4'h7: seg = 7'b1111000; // 7
      4'h8: seg = 7'b0000000; // 8
      4'h9: seg = 7'b0010000; // 9
      4'hA: seg = 7'b0001000; // A
      4'hB: seg = 7'b0000011; // B
      4'hC: seg = 7'b1000110; // C
      4'hD: seg = 7'b0100001; // D
      4'hE: seg = 7'b0000110; // E
      4'hF: seg = 7'b0001110; // F
      default: seg = 7'b1111111; // All segments off
    endcase
  end
endmodule

// --------------------------- 4-digit Display Mux ----------------------------
// Module to multiplex four 7-segment display digits.
module sevenseg_mux(
  input  wire         clk,        // 100 MHz clock
  input  wire [6:0]   d3_seg,     // leftmost digit (AN3) segments
  input  wire [6:0]   d2_seg,     // AN2 segments
  input  wire [6:0]   d1_seg,     // AN1 segments
  input  wire [6:0]   d0_seg,     // rightmost digit (AN0) segments
  output reg  [3:0]   an,         // Anode enables (active-low)
  output reg  [6:0]   seg,        // Segment lines (a-g)
  output wire         dp          // Decimal point
);
  assign dp = 1'b1; // DP off (active-low)

  // Counter for the multiplexing rate
  reg [15:0] div = 16'd0;
  reg [1:0]  sel = 2'd0; // Digit selector (0 to 3)

  // Divide the clock for a refresh rate of ~1 kHz per digit
  always @(posedge clk) begin
    div <= div + 16'd1;
    sel <= div[15:14];  // Use bits [15:14] for 4 counts (100MHz / 2^16 ? 1.5kHz)
  end

  // Combinational logic to select which digit's segments to display
  always @* begin
    case (sel)
      2'd0: begin an = 4'b1110; seg = d0_seg; end // AN0 (rightmost) selected
      2'd1: begin an = 4'b1101; seg = d1_seg; end // AN1 selected
      2'd2: begin an = 4'b1011; seg = d2_seg; end // AN2 selected
      2'd3: begin an = 4'b0111; seg = d3_seg; end // AN3 (leftmost) selected
      default: begin an = 4'b1111; seg = 7'b1111111; end // All off/blank
    endcase
  end
endmodule

// ---------------------------------- TOP -------------------------------------
// Top-level module for the UART TX
module uart_tx_demo_top(
  input  wire          CLK100MHZ,   // Main clock input
  input  wire          btnL,        // Left pushbutton (trigger)
  input  wire [15:0] SW,            // Switches for data input (using SW[7:0])
  output wire          uart_txd,    // UART Transmit Data pin
  output wire [3:0] AN,             // 7-segment display Anode enables
  output wire          CA,CB,CC,CD,CE,CF,CG, // 7-segment display segment lines
  output wire          DP           // 7-segment display Decimal Point
);
  // ---- Trigger & baud ----
  wire tx_start;
  // Instantiate button debouncer and one-shot pulse generator
  btn_sync_oneshot U_BTN(
    .clk(CLK100MHZ),
    .btn_async(btnL),
    .pulse(tx_start) // Pulse on button press
  );

  wire baud_tick;
  // Instantiate baud rate generator (9600 baud for 100MHz clock)
  baud_gen #(.CLK_HZ(100_000_000), .BAUD(9600)) U_BAUD(
    .clk (CLK100MHZ),
    .tick(baud_tick)
  );

  // ---- UART TX ----
  reg         start_i = 1'b0; // Internal 'start' signal for UART TX
  reg [7:0] data_i  = 8'h00;  // Data to send
  wire        tx_busy;        // UART TX busy status

  // Instantiate the UART Transmit module
  uart_tx U_TX(
    .clk  (CLK100MHZ),
    .tick (baud_tick),
    .start(start_i),
    .data (data_i),
    .txd  (uart_txd), // Connect to output pin
    .busy (tx_busy)
  );

  // FSM to control the UART transmission process
  // Send SW[7:0] once per BTNL press
  localparam S_IDLE = 1'b0, S_SEND = 1'b1;
  reg state = S_IDLE;

  always @(posedge CLK100MHZ) begin
    start_i <= 1'b0; // Default: don't start
    case (state)
      S_IDLE: if (tx_start && !tx_busy) begin // Wait for button press AND not busy
              data_i  <= SW[7:0]; // Load data from switches
              start_i <= 1'b1;    // Initiate transmission (1-clock pulse)
              state   <= S_SEND;  // Move to sending state
              end
      S_SEND: if (!tx_busy) state <= S_IDLE; // Wait until transmission is complete
    endcase
  end

  // ---- Display: show last sent byte on LEFT two digits (HI then LO) ----
  reg [7:0] last_tx = 8'h00; // Stores the last byte sent
  reg         show_en = 1'b0;  // Display enable flag
  
  // Latch the switch data when a transmission starts (button press)
  always @(posedge CLK100MHZ) if (tx_start) begin
    last_tx <= SW[7:0];
    show_en <= 1'b1; // Enable display
  end

  wire [6:0] seg_blank = 7'b1111111; // All segments off
  wire [6:0] seg_hi, seg_lo;

  // Convert the high and low nibbles of the last sent byte to 7-segment codes
  hex7seg H_HI(.nib(last_tx[7:4]), .seg(seg_hi)); // High nibble (AN3)
  hex7seg H_LO(.nib(last_tx[3:0]), .seg(seg_lo)); // Low nibble (AN2)

  // AN3 AN2 AN1 AN0 = [HI] [LO] [blank] [blank]
  wire [6:0] d3 = show_en ? seg_hi : seg_blank; // Leftmost digit (AN3)
  wire [6:0] d2 = show_en ? seg_lo : seg_blank; // Second digit (AN2)
  wire [6:0] d1 = seg_blank;                     // Third digit (AN1)
  wire [6:0] d0 = seg_blank;                     // Rightmost digit (AN0)

  wire [6:0] seg_bus;
  // Instantiate the 4-digit display multiplexer
  sevenseg_mux U_MUX(
    .clk(CLK100MHZ),
    .d3_seg(d3), .d2_seg(d2), .d1_seg(d1), .d0_seg(d0), // Input segments
    .an(AN), .seg(seg_bus), .dp(DP) // Output enables and segments
  );

  // Map {a,b,c,d,e,f,g} from the multiplexer output to the physical pins
  // CA-CG are the physical segment pins (active-low)
  assign {CA,CB,CC,CD,CE,CF,CG} =
           {seg_bus[0], seg_bus[1], seg_bus[2],
            seg_bus[3], seg_bus[4], seg_bus[5], seg_bus[6]};
endmodule