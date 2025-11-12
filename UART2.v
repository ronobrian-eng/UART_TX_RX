// ============================================================================
// EGR 601 - Lab 9 Part II
// UART TX & RX
// Description: Implements full duplex 8N1 UART communication (Transmit and Receive)
//              and displays the last transmitted and last latched received byte
//              on a 4-digit 7-segment display.
// ============================================================================

`timescale 1ns/1ps

// --------------------------- Debounce + One-shot ----------------------------
// Module to debounce an asynchronous button and generate a 1-clock pulse on press.
module btn_sync_oneshot(
  input  wire clk,           // 100 MHz clock
  input  wire btn_async,     // mechanical button (active-high)
  output wire pulse          // 1-clock pulse on rising edge of debounced signal
);
  // 2-Flip-Flop Synchronizer
  reg [2:0] sync;
  always @(posedge clk) sync <= {sync[1:0], btn_async};

  // 3-Tap Majority Debounce logic
  wire deb = (sync[2] & sync[1]) | (sync[1] & sync[0]) | (sync[2] & sync[0]);

  // Delayed debounced signal
  reg deb_d;
  always @(posedge clk) deb_d <= deb;

  // One-shot pulse: generates a 1-clock pulse on the rising edge (press)
  assign pulse = deb & ~deb_d;
endmodule

// ------------------------------- Baud tick (TX) -----------------------------
// Module to generate a 1-clock tick at the specified baud rate for TX timing.
module baud_gen #(
  parameter CLK_HZ = 100_000_000,
  parameter BAUD   = 9600
)(
  input  wire clk,
  output reg  tick // 1-clock pulse, one per bit time
);
  // Counter limit for clock division: DIV = CLK_HZ / BAUD (rounded)
  localparam integer DIV = (CLK_HZ + BAUD/2) / BAUD; // 100e6/9600 ? 10417
  reg [15:0] cnt = 16'd0;
  
  always @(posedge clk) begin
    if (cnt == DIV-1) begin
      cnt  <= 16'd0;    // Reset counter
      tick <= 1'b1;     // Generate tick
    end else begin
      cnt  <= cnt + 1'b1; // Increment counter
      tick <= 1'b0;     // No tick
    end
  end
endmodule

// -------------------------------- UART TX -----------------------------------
// Module to transmit a byte (8-N-1 format) controlled by a clock-rate 'tick'.
module uart_tx(
  input  wire        clk,
  input  wire        tick,    // 1 pulse per bit time
  input  wire        start,    // 1-clk pulse to start transmit
  input  wire [7:0] data,     // Data byte to transmit
  output reg         txd,      // Transmit Data output (idle high)
  output reg         busy      // High when transmission is in progress
);
  // State machine parameters
  localparam [1:0] ST_IDLE  = 2'd0,  // Waiting for 'start'
                   ST_START = 2'd1,  // Start Bit (low)
                   ST_DATA  = 2'd2,  // 8 Data Bits
                   ST_STOP  = 2'd3;  // Stop Bit (high)

  reg [1:0] state = ST_IDLE; // Current state
  reg [7:0] shifter;         // Shift register for data
  reg [2:0] bit_idx;         // Data bit counter (0 to 7)

  initial begin
    txd  = 1'b1; // TX line idle is high
    busy = 1'b0;
  end

  // FSM driven by 'tick' when in active states
  always @(posedge clk) begin
    case (state)
      ST_IDLE: begin
        txd  <= 1'b1;
        busy <= 1'b0;
        if (start) begin
          shifter <= data;
          bit_idx <= 3'd0;
          busy    <= 1'b1;
          state   <= ST_START;
        end
      end

      ST_START: if (tick) begin
        txd   <= 1'b0;          // Transmit Start Bit (logic 0)
        state <= ST_DATA;
      end

      ST_DATA: if (tick) begin
        txd     <= shifter[0];             // Transmit LSB first
        shifter <= {1'b0, shifter[7:1]};   // Shift right
        if (bit_idx == 3'd7) state <= ST_STOP; // 8 bits done
        bit_idx <= bit_idx + 1'b1;
      end

      ST_STOP: if (tick) begin
        txd   <= 1'b1;          // Transmit Stop Bit (logic 1)
        state <= ST_IDLE;
      end
    endcase
  end
endmodule

// ============================================================================
// UART RX (self-timed, half-bit sampling)
// ============================================================================
// Module to receive a byte (8-N-1) using oversampling and mid-bit sampling.
module uart_rx #(
    parameter CLK_FREQ         = 100_000_000,      // System clock frequency
    parameter BAUD_RATE        = 9600,             // Target baud rate
    parameter BAUD_COUNT_MAX = CLK_FREQ / BAUD_RATE, // Clock cycles per bit time (~10417)
    parameter BAUD_BITS      = 14                // Size of baud counter (ceil(log2(BAUD_COUNT_MAX)))
)(
    input  wire          clk,      // 100 MHz clock
    input  wire          RxD,      // Serial input line (idle=1)
    output reg  [7:0]    rdata,    // Received byte output
    output reg           r_done    // 1-clk pulse on byte ready
);
  // State machine parameters for RX process
  localparam [2:0] MARK=3'd0,   // Idle state, waiting for start bit (RxD=1)
                   START=3'd1,  // Waiting for middle of start bit
                   DELAY=3'd2,  // (Not used here, shifted to be part of SHIFT state)
                   SHIFT=3'd3,  // Sample data bits
                   STOP=3'd4;   // Wait for stop bit

  reg  [2:0]  state = MARK;
  reg  [BAUD_BITS-1:0] baud_count = {BAUD_BITS{1'b0}}; // Counter for clock cycles per bit
  reg  [3:0]  bit_count = 4'd0;                       // Counter for the 8 data bits
  reg  [7:0]  rx_shift_reg = 8'h00;                   // Register to assemble the received byte

  // 2-FF Synchronizer on the asynchronous RxD input to prevent metastability
  reg rxd_q1=1'b1, rxd_q2=1'b1;
  always @(posedge clk) begin
    rxd_q1 <= RxD;
    rxd_q2 <= rxd_q1; // Synchronized, debounced RxD signal
  end

  always @(posedge clk) begin
    // Default 'r_done' to low except in the final state
    if (state == MARK) r_done <= 1'b0;

    // Baud Counter: counts clock cycles up to BAUD_COUNT_MAX-1
    // Only advances in active receiving states (START, SHIFT, STOP)
    if (state==START || state==SHIFT || state==STOP) begin
      if (baud_count == BAUD_COUNT_MAX-1) baud_count <= 0;
      else                             baud_count <= baud_count + 1'b1;
    end else begin
      baud_count <= 0; // Reset in MARK/IDLE state
    end

    case (state)
      // Idle state: waiting for a falling edge on the synchronized RxD
      MARK: begin
        if (rxd_q2 == 1'b0) begin // Detect start bit falling edge
          state      <= START;
          baud_count <= 0; // Reset counter to time the start bit
        end
      end

      // Sample middle of Start Bit (low = 1/2 bit time)
      START: begin
        // Wait for half a bit time
        if (baud_count == (BAUD_COUNT_MAX/2)-1) begin
          if (rxd_q2 == 1'b0) begin
            // Confirmed start bit: reset counter to align to middle of bit 0
            baud_count <= 0;
            bit_count  <= 0;
            state      <= SHIFT;    // Move to data bit sampling
          end else begin
            state <= MARK;           // Spurious glitch/noise, return to idle
          end
        end
      end

      // Sample each of the 8 data bits (1 full bit time each)
      SHIFT: begin
        if (baud_count == BAUD_COUNT_MAX-1) begin // Check at end of bit time
          baud_count   <= 0;
          // Shift the sampled bit (rxd_q2) into the MSB (LSB first protocol)
          rx_shift_reg <= {rxd_q2, rx_shift_reg[7:1]}; 
          
          if (bit_count == 4'd7) begin // If 8th bit was just sampled
            state <= STOP;
          end else begin
            bit_count <= bit_count + 1'b1; // Increment bit counter
          end
        end
      end

      // Stop-bit wait: wait one full bit time for the stop bit (must be high)
      STOP: begin
        if (baud_count == BAUD_COUNT_MAX-1) begin
          rdata  <= rx_shift_reg; // Output the received byte
          r_done <= 1'b1;         // Signal 'Data Ready' pulse
          state  <= MARK;         // Return to idle state
          baud_count <= 0;
        end
      end

      default: state <= MARK;
    endcase
  end

endmodule

// ----------------------------- Hex to 7-segment -----------------------------
// Combinational logic to convert 4-bit hex nibble to 7-segment display pattern.
// Bit order = {a,b,c,d,e,f,g}, active-low (0 = ON)
module hex7seg(
  input  wire [3:0] nib,
  output reg  [6:0] seg
);
  always @* begin
    case (nib)
// Bit pattern: {a,b,c,d,e,f,g} where 0=ON, 1=OFF
4'h0: seg = 7'b1000000;
4'h1: seg = 7'b1111001;
4'h2: seg = 7'b0100100;
4'h3: seg = 7'b0110000;
4'h4: seg = 7'b0011001;
4'h5: seg = 7'b0010010;
4'h6: seg = 7'b0000010;
4'h7: seg = 7'b1111000;
4'h8: seg = 7'b0000000;
4'h9: seg = 7'b0010000;
4'hA: seg = 7'b0001000;
4'hB: seg = 7'b0000011;
4'hC: seg = 7'b1000110;
4'hD: seg = 7'b0100001;
4'hE: seg = 7'b0000110;
4'hF: seg = 7'b0001110;
default: seg = 7'b1111111; // Blank display

    endcase
  end
endmodule

// --------------------------- 4-digit Display Mux ----------------------------
// Time-multiplexes the four 7-segment display digits.
module sevenseg_mux(
  input  wire         clk,        // 100 MHz
  input  wire [6:0]   d3_seg,     // leftmost (AN3)
  input  wire [6:0]   d2_seg,
  input  wire [6:0]   d1_seg,
  input  wire [6:0]   d0_seg,     // rightmost (AN0)
  output reg  [3:0]   an,         // Anode enables (active-low)
  output reg  [6:0]   seg,        // Shared segment lines
  output wire         dp
);
  assign dp = 1'b1; // DP off (active-low)
  reg [15:0] div = 16'd0;
  reg [1:0]  sel = 2'd0; // Digit selector

  always @(posedge clk) begin
    div <= div + 16'd1;
    sel <= div[15:14];  // Generates a switching rate of ~1.5 kHz per digit
  end

  // Select which digit is active and what segments to display
  always @* begin
    case (sel)
      2'd0: begin an = 4'b1110; seg = d0_seg; end // AN0 (rightmost) selected
      2'd1: begin an = 4'b1101; seg = d1_seg; end // AN1 selected
      2'd2: begin an = 4'b1011; seg = d2_seg; end // AN2 selected
      2'd3: begin an = 4'b0111; seg = d3_seg; end // AN3 (leftmost) selected
      default: begin an = 4'b1111; seg = 7'b1111111; end
    endcase
  end
endmodule

// ---------------------------------- TOP -------------------------------------
// Top-level module orchestrating UART TX/RX and 7-segment display.
module EGR601_Lab9_Top(
  input  wire          CLK100MHZ,
  input  wire [15:0] SW,            // SW[7:0] used as data for TX
  input  wire          BTNL,        // Trigger TX & latch value to left display
  input  wire          BTNR,        // Latch latest RX to right display
  input  wire          RxD,         // Serial Data In (from PC)
  output wire          TxD,         // Serial Data Out (to PC)
  output wire [3:0] AN,             // 7-seg Anode enables
  output wire          CA,CB,CC,CD,CE,CF,CG, // 7-seg Segment lines
  output wire          DP           // 7-seg Decimal Point
);

  // ---------------- TX path ----------------
  wire tx_tick;
  // Generate baud rate timing pulse for TX
  baud_gen #(.CLK_HZ(100_000_000), .BAUD(9600)) U_BAUD(.clk(CLK100MHZ), .tick(tx_tick));

  wire tx_start_pulse;
  // Button L generates a 1-clock pulse to start transmission
  btn_sync_oneshot U_BTN_L(.clk(CLK100MHZ), .btn_async(BTNL), .pulse(tx_start_pulse));

  reg         tx_start_i = 1'b0; // Internal 'start' signal to UART TX
  reg [7:0] tx_data_i  = 8'h00; // Data to be sent
  wire        tx_busy;           // UART TX busy flag

  // Instantiate the UART TX module
  uart_tx U_TX(
    .clk  (CLK100MHZ),
    .tick (tx_tick),
    .start(tx_start_i),
    .data (tx_data_i),
    .txd  (TxD), // Connect to output pin
    .busy (tx_busy)
  );

  // FSM to control one transmission cycle when BTNL is pressed
  localparam S_IDLE = 1'b0, S_SEND = 1'b1;
  reg state = S_IDLE;

  always @(posedge CLK100MHZ) begin
    tx_start_i <= 1'b0; // Default: do not start
    case (state)
      S_IDLE: if (tx_start_pulse && !tx_busy) begin // Wait for button press & not busy
              tx_data_i  <= SW[7:0]; // Load data from switches
              tx_start_i <= 1'b1;    // Send 1-clock pulse to start UART
              state      <= S_SEND;
              end
      S_SEND: if (!tx_busy) state <= S_IDLE; // Wait for TX module to finish
    endcase
  end

  // Latch the value sent for display on the left two digits (AN3, AN2)
  reg         show_tx_en = 1'b0; // Display enable flag for TX value
  reg [7:0] tx_disp    = 8'h00; // Data latched for TX display
  always @(posedge CLK100MHZ) if (tx_start_pulse) begin
    tx_disp    <= SW[7:0]; // Latch switch value at start of TX
    show_tx_en <= 1'b1;    // Enable display
  end

  // ---------------- RX path ----------------
  wire [7:0] rx_byte; // Latest received byte
  wire        rx_done; // 1-clock pulse when a byte is successfully received
  // Instantiate the UART RX module
  uart_rx U_RX(
    .clk  (CLK100MHZ),
    .RxD  (RxD), // Connect to input pin
    .rdata (rx_byte),
    .r_done(rx_done)
  );

  // Buffer to hold the latest received byte indefinitely
  reg [7:0] rx_buf = 8'h00;
  always @(posedge CLK100MHZ) if (rx_done) rx_buf <= rx_byte; // Update buffer on new byte

  wire rx_latch_pulse;
  // Button R generates a 1-clock pulse to latch the received value
  btn_sync_oneshot U_BTN_R(.clk(CLK100MHZ), .btn_async(BTNR), .pulse(rx_latch_pulse));

  // Latch the received byte (rx_buf) for display on the right two digits (AN1, AN0)
  reg         show_rx_en = 1'b0; // Display enable flag for RX value
  reg [7:0] rx_disp    = 8'h00; // Data latched for RX display
  always @(posedge CLK100MHZ) if (rx_latch_pulse) begin
    rx_disp    <= rx_buf; // Latch the buffered RX data when BTNR is pressed
    show_rx_en <= 1'b1;   // Enable display
  end

  // ---------------- 7-seg content ----------------
  wire [6:0] seg_blank = 7'b1111111; // All segments off

  wire [6:0] tx_hi_seg, tx_lo_seg, rx_hi_seg, rx_lo_seg;
  // Convert latched TX value (HI/LO nibbles)
  hex7seg H_TX_HI(.nib(tx_disp[7:4]), .seg(tx_hi_seg));
  hex7seg H_TX_LO(.nib(tx_disp[3:0]), .seg(tx_lo_seg));
  // Convert latched RX value (HI/LO nibbles)
  hex7seg H_RX_HI(.nib(rx_disp[7:4]), .seg(rx_hi_seg));
  hex7seg H_RX_LO(.nib(rx_disp[3:0]), .seg(rx_lo_seg));

  // Define segments for the four digits: [TX_HI] [TX_LO] [RX_HI] [RX_LO]
  // AN3 (leftmost) AN2         AN1         AN0 (rightmost)
  wire [6:0] d3 = show_tx_en ? tx_hi_seg : seg_blank; // Display TX HI if enabled
  wire [6:0] d2 = show_tx_en ? tx_lo_seg : seg_blank; // Display TX LO if enabled
  wire [6:0] d1 = show_rx_en ? rx_hi_seg : seg_blank; // Display RX HI if enabled
  wire [6:0] d0 = show_rx_en ? rx_lo_seg : seg_blank; // Display RX LO if enabled

  wire [6:0] seg_bus;
  // Instantiate the display multiplexer
  sevenseg_mux U_MUX(
    .clk(CLK100MHZ),
    .d3_seg(d3), .d2_seg(d2), .d1_seg(d1), .d0_seg(d0),
    .an(AN), .seg(seg_bus), .dp(DP)
  );

  // Map the multiplexed segment bus (seg_bus = {a,b,c,d,e,f,g}) to the physical pins
  assign {CA,CB,CC,CD,CE,CF,CG} = {seg_bus[0], seg_bus[1], seg_bus[2],
                                   seg_bus[3], seg_bus[4], seg_bus[5], seg_bus[6]};
endmodule