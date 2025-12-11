# UART_Tx_and_Rx
FPGA-based UART interface to display decimal and hexadecimal values on dual 4-digit 7-segment displays and 8-bit LEDs. Receives data via Docklight software, converts to BCD for decimal display, and echoes input back. Designed for   Boolean Board.

# UART to 7-Segment FPGA Display

## Overview
This project demonstrates an FPGA-based system that receives 8-bit data over UART from a PC terminal (using **Docklight software**) and displays:

- Decimal value on a 4-digit 7-segment display.
- Hexadecimal value on a separate 4-digit 7-segment display.
- Binary representation on 8 LEDs.

The system also echoes received data back to the PC. The 7-segment displays use time-multiplexing for flicker-free output.

## Features
- UART Receiver & Transmitter for serial communication.
- Clocked Binary-to-BCD conversion for decimal display.
- Dual 4-digit multiplexed 7-segment displays:
  - Decimal display.
  - Hexadecimal display.
- Active-low LED output for binary display.
- Tested with Spartan 7 FPGA boards.
- Compatible with Docklight or any serial terminal software.

## Hardware Connections
| FPGA Pin       | Signal                  |
|----------------|------------------------|
| RX             | UART input from PC      |
| TX             | UART output to PC       |
| LEDs[7:0]      | Binary display output   |
| Seg[7:0]       | Decimal 7-segment output|
| AN[3:0]        | Decimal digit enable    |
| Seg_Hex[7:0]   | Hexadecimal 7-segment   |
| AN_Hex[3:0]    | Hexadecimal digit enable|

## Modules
- `uart_rx.v` – UART receiver (8-bit)
- `uart_tx.v` – UART transmitter (8-bit)
- `bin2bcd.v` – Binary to 4-digit BCD converter
- `seg7_decoder_8.v` – 7-segment decoder (active-low)
- `seg7_display_4digit.v` – Multiplexed 4-digit display driver
- `uart_fpga_display.v` – Top-level module integrating all components

## Getting Started
1. Connect your FPGA to the PC via UART.
2. Open **Docklight** and configure serial port: 115200 baud, 8N1.
3. Program the FPGA with `uart_fpga_display`.
4. Send 8-bit values via Docklight and observe:
   - Decimal value on the first 4-digit display.
   - Hexadecimal value on the second 4-digit display.
   - Binary value on LEDs.
5. The FPGA echoes back received data for verification.



