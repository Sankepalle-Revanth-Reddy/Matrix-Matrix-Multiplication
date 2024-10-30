# Matrix-Matrix-Multiplication

This project involves designing, implementing, simulating, and synthesizing a hardware system for performing matrix-matrix multiplication (MMM). The system is built using SystemVerilog and is broken down into five main parts:
-->Multiply-Accumulate (MAC) Unit
-->Output FIFO
-->Input Memory Module
-->Matrix-Matrix Multiplier (MMM) Integration
-->Throughput Optimization


///////----Key Features----//////
Parameterized design allowing flexible matrix dimensions (M x K and K x N)
Support for variable bit widths for input and output values
AXI-Stream protocol for input and output interfaces
Scalable architecture supporting matrices of various sizes
Project Structure
The project is divided into five parts, each focusing on a specific component or aspect of the system:
Part 1: Multiply-Accumulate Unit
Part 2: Output FIFO
Part 3: Input Memory Module
Part 4: Matrix-Matrix Multiplier (MMM) Integration
Part 5: Throughput Optimization


///////----Technical Specifications----//////  
Supports matrix dimensions: M ≥ 2, N ≥ 2, MAXK ≥ 2
Input bit width (INW): 2 ≤ INW ≤ 32 bits
Output bit width (OUTW): 2*INW ≤ OUTW ≤ 64 bits
Uses simplified AXI-Stream protocol for data transfer
Implements saturating arithmetic to handle potential overflow
Tools and Environment
Simulation: QuestaSim
Synthesis: Details provided in project documents
Project Goals
Design an efficient and correct MMM hardware system
Implement the system using SystemVerilog
Simulate and verify the design's functionality
Synthesize the design and analyze its performance
Optimize the system for improved throughput
This project offers hands-on experience in digital design, hardware description languages, and computer architecture, focusing on a practical application of matrix multiplication in hardware.
