# Real Time FPGA FFT Spectrum Analyzer with VGA output (VHDL)
A real-time FFT spectrum analyzer implemented in VHDL on the ZedBoard Zynq-7000 SoC. This project processes digital signals using a 128-point fixed-point FFT and visualizes their frequency spectra as dynamic bar graphs on a 640×480 VGA display. It demonstrates complete end-to-end DSP architecture on FPGA, including signal sampling, FFT pipeline, magnitude calculation, buffering, and synchronized VGA rendering, with modular design and efficient resource usage. Developed entirely using Vivado Design Suite, leveraging Xilinx IP cores and custom VHDL modules.

---

# Project Purpose and Learning Goals

This project demonstrates:

Real-time DSP implementation on FPGA

VHDL RTL design with AXI-Stream interfaces

Integration of Xilinx IP cores (FFT and Clocking Wizard)

Modular digital system architecture

VGA video output and raster-based rendering

End-to-end understanding of frequency domain visualization

---

# Technical Specifications

Input Signal: 128-point ROM-based sine wave (fixed-point)

FFT Core: 128-point radix-2 burst mode, fixed-point, scaled output

Display: VGA (640x480 @ 60 Hz) using 25 MHz pixel clock

Clock Source: 100 MHz system clock -> 25 MHz via Clocking Wizard

Platform: ZedBoard Zynq-7000 FPGA

---

# System Architecture
+----------------+      +--------------+      +----------------+      +---------------+
| Signal Capture | -->  |  FFT Wrapper | -->  | Magnitude Calc | -->  | Bar Buffer    |
+----------------+      +--------------+      +----------------+      +---------------+
                                                                          |
                                                                          v
                                                                 +------------------+
                                                                 | VGA Display (Bars)|
                                                                 +------------------+

---

# Design Process

1. Signal Capture (signal_capture.vhd)

128-point ROM stores a test sine wave

Sampled in sequence, synchronized to FFT start trigger

2. FFT Wrapper (fft_wrapper.vhd)

Concatenates 16-bit real signal with zero imaginary part

Interfaces with Xilinx FFT IP via AXI-Stream

Handles handshaking, streaming control, and FFT trigger

3. Magnitude Computation (fft_magnitude.vhd)

Computes real sq + imag sq

Scales result down to 8-bit height values (0–255)

4. Bar Buffer (bar_buffer.vhd)

Stores the 128 scaled magnitudes

Used by VGA to draw bar heights per frequency bin

5. VGA Sync and Display (vga_sync.vhd + vga_display.vhd)

Generates horizontal/vertical sync pulses

Renders vertical bars (5 pixels wide per bin) using line-by-line comparison

6. Top-Level Integration (fft_spectrum_top.vhd)

Wires all modules

Drives FFT control, bar address incrementing, VGA clock

Uses Clocking Wizard for pixel clock generation

---

# Output Image
![IMG_2775 (2)](https://github.com/user-attachments/assets/18d0f6c4-edbf-4bc3-a3de-1826d1bf6a8d)

This is the output fro my monitor for the given sampled sine wave in the ROM table of signal capture

---

# Tools used
Vivado Design Suite (version used 2025.1)
Zedboard Zynq-7000 xc7z020clg484-1
VGA cable and compatible monitor for display



