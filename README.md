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

## 📈 Results
Achieved stable **full-duplex UART communication** verified via:
- Simulation waveforms showing correct start, data, and stop bits  
- Real serial data exchange between FPGA and PC using Tera Term  
- Accurate hexadecimal display on the Basys-3 7-segment module  

## 📡 Applications
- Embedded system serial interfaces  
- FPGA-based communication protocol design  
- Educational and research demonstrations in digital communication  

## 👤 Author
**Brian Rono**  
Electrical & Computer Engineer | FPGA  •  Embedded Systems  •  Wireless Tech  
🔗 [GitHub Profile](https://github.com/ronobrian-eng)
