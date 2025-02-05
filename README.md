# 5B/6B Encoding with CRC Error Detection – Verilog Simulation

## Overview

This project simulates a digital communication system that implements 5B/6B encoding and CRC-based error detection using Verilog. The simulation models two consecutive transmission stages:

1. **First Transmission (130-bit data word):**  
   - A 130-bit data word is generated with fixed control bits (bit 0 = 0 and bit 1 = 1) and random values for the remaining bits.  
   - The data is transmitted bit-by-bit, with an intentional error injected (flipping bit 50).  
   - A CRC8 checksum (using polynomial 0x07) is computed over the 130-bit word to detect any transmission errors.

2. **Second Transmission (156-bit encoded data):**  
   - The received 130-bit word is split into twenty-six 5-bit blocks.  
   - Each 5-bit block is mapped to a 6-bit code using a 5B/6B lookup table.  
   - The encoded 156-bit data (26 blocks of 6 bits each) is transmitted; for each block, a single bit is randomly flipped to simulate channel errors.  
   - A per-block CRC is computed for error checking.  
   - Finally, the 6-bit blocks are decoded back into 5-bit blocks and reassembled into a 130-bit word.

The simulation then compares the decoded data with the original data (ignoring the fixed control bits) and reports the number of errors along with CRC mismatches observed in each stage.

## Features

- **130-bit Data Generation:**  
  Fixed control bits and randomly generated data bits.

- **Bit-by-Bit Transmission with Error Injection:**  
  The first transmission intentionally flips bit 50 to simulate an error.

- **5B/6B Encoding:**  
  Each group of 5 bits is mapped to a corresponding 6-bit code to ensure DC balance and improved signal integrity.

- **CRC8 Error Detection:**  
  CRC is computed over the original data as well as on a per-block basis for the encoded data to detect transmission errors.

- **Decoding and Error Reporting:**  
  The encoded data is decoded back to 5-bit blocks and reassembled. Mismatches between the original and decoded data are reported, along with the CRC errors from both transmission stages.

## How to Run the Simulation

1. **Simulation Environment:**  
   Use any Verilog simulator such as ModelSim, Icarus Verilog, or a similar tool.

2. **Compile the Code:**  
   Compile the top-level testbench file (e.g., `transmission_sim.v`).

3. **Run the Simulation:**  
   Execute the simulation. The output will detail each transmission step, CRC check results, encoding/decoding process, and a final error summary.

4. **Review the Output:**  
   The simulation log will display:
   - The original 130-bit data.
   - Bit-level transmission details with injected errors.
   - Encoding and per-block CRC mismatch messages.
   - Decoding results with mismatches indicated.
   - A summary report of data bit errors and CRC errors.

## Code Structure

- **Encoding and Decoding Functions:**  
  The Verilog functions `encode5b6b` and `decode6b5b` implement the 5B/6B lookup table for converting between 5-bit and 6-bit data.

- **CRC Functions:**  
  Two functions, `calc_crc8_130` and `calc_crc8_6`, compute CRC8 checksums for the 130-bit data word and for each 6-bit block, respectively.

- **Testbench:**  
  The top-level testbench (`transmission_sim.v`) models the complete transmission system. It generates the original data, simulates both transmission stages with error injection, performs encoding/decoding, and reports error statistics.

## Conclusion

This repository demonstrates a complete simulation of a digital communication system with error detection and encoding mechanisms. It is useful for understanding the effects of transmission errors on encoded data and the effectiveness of CRC in error detection. Feel free to explore, modify, and extend the code for further experimentation or integration into larger projects.
