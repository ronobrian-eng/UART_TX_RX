# UART TX/RX Communication on Basys-3

## Overview
Design and implementation of UART transmitter and receiver modules (9600 bps, 8N1) using Verilog on the Basys-3 FPGA.  
The system transmits and receives data through serial communication and displays hex output on the 7-segment display.

## Features
- Debounced TX trigger on **BTNL**, RX latch on **BTNR**
- Baud-rate generator: 100 MHz → 9600 bps
- Displays TX/RX data on 7-segment display
- Verified through simulation and real communication using Tera Term
- Modular design: `uart_tx.v`, `uart_rx.v`, and `uart_top.v`

## Files
| File | Description |
|------|--------------|
| `uart_tx.v` | Transmitter logic |
| `uart_rx.v` | Receiver logic |
| `uart_top.v` | Integration module |
| `tb_uart_tx.v` | TX Testbench |
| `tb_uart_txrx.v` | RX Testbench |
| `UART1.xdc` | Pin constraints |
| `UART2.xdc` | Pin constraints |

## Tools & Hardware
Vivado 2023.2 · Basys-3 (Artix-7 xc7a35tcpg236-1)

## Results
Achieved full-duplex UART operation validated by simulation and live serial exchange with PC terminal/Teraterm.
