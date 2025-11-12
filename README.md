# UART TX/RX Communication on Basys-3 FPGA

## 📘 Overview
This project demonstrates the design and implementation of **UART Transmitter and Receiver modules** (9600 bps, 8N1) using **Verilog HDL** on the **Basys-3 FPGA (Artix-7 xc7a35tcpg236-1)**.  
The system performs reliable full-duplex serial communication between the FPGA and a PC terminal (Tera Term) while displaying hexadecimal data on the on-board 7-segment display.

## ⚙️ Features
- Debounced **BTNL** for TX trigger and **BTNR** for RX latch  
- **Baud-rate generator:** 100 MHz → 9600 bps  
- Displays TX and RX data on the 7-segment display  
- Modular architecture separating TX, RX, and top integration units  
- Simulation validation followed by hardware testing through Tera Term  

## 🧩 File Summary
| File | Description |
|------|--------------|
| `uart_tx.v` | UART Transmitter logic |
| `uart_txrx.v` | UART Receiver logic |
| `tb_uart_tx.v` | TX module testbench |
| `tb_uart_txrx.v` | RX/Integration testbench |
| `uart_tx.xdc` | Basys-3 constraint file (TX) |
| `uart_txrx.xdc` | Basys-3 constraint file (RX) |

## 🧪 Tools & Hardware
- **Vivado 2023.2**  
- **Basys-3 FPGA (Board: xc7a35tcpg236-1)**  
- **Tera Term Serial Monitor**  
- **100 MHz on-board oscillator**

## 🧪 Results

### Part 1 – UART Transmitter (TX)
In this stage, the **UART TX** module was designed and simulated at 9600 bps (8N1).  
The waveform shows correct **start bit → 8 data bits → stop bit** framing.  
On the Basys-3 board, pressing **BTNL** triggered transmission and displayed the sent hex value on the 7-segment display.  
Tera Term verified that the transmitted ASCII character (0x41 = ‘A’) was correctly received on the PC.

| UART TX Frame Simulation | UART TX Waveforms Snapshot | Console Output |
|---------------------------|--------------------------|----------------|
| ![UART Frame](screenshots/p1_uart_frame.png) | ![Display Snapshot](screenshots/p1_display_snapshot.png) | ![Console Log](screenshots/p1_console_log.png) |

---

### Part 2 – UART Transmitter + Receiver (TX/RX Loopback)
This phase integrated both **TX and RX** modules into a full **loopback communication system**.  
The FPGA transmitted data via TX and simultaneously received it on RX, confirming proper synchronization and bit-level accuracy.  
Loopback timing and 7-segment latched display validated the system’s reliability on real hardware.

| Loopback Timing Simulation | Latched RX Display | Tera Term Console |
|-----------------------------|--------------------|-------------------|
| ![Loopback Timing](screenshots/p2_loopback_timing.png) | ![Latched RX Display](screenshots/p2_latched_rx_display.png) | ![RX Console Log](screenshots/p2_console_log.png) |

---

### 📊 Observations
- TX-only (Part 1) confirmed accurate serial frame generation.  
- TX/RX loopback (Part 2) achieved stable full-duplex operation with zero bit errors.  
- Baud-rate timing matched theoretical 9600 bps expectations.  

✅ **Conclusion:** The UART TX/RX design achieved reliable full-duplex serial communication between the Basys-3 FPGA and PC, verified in both simulation and hardware loopback.


## 📡 Applications
- Embedded system serial interfaces  
- FPGA-based communication protocol design  
- Educational and research demonstrations in digital communication  

## 👤 Author
**Brian Rono**  
Electrical & Computer Engineer | FPGA  •  Embedded Systems  •  Wireless Tech  
🔗 [GitHub Profile](https://github.com/ronobrian-eng)
