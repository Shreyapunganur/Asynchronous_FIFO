#Async FIFO Design (Verilog)

##Overview
This repository presents a robust and scalable asynchronous FIFO (First-In-First-Out queue) implemented in Verilog. It allows reliable data transfer between two independent, asynchronous clock domains, leveraging dual-flip-flop synchronizers and Gray-coded pointers to guarantee metastability-free operation.

##Features
Dual Clock Asynchronous FIFO: Safe data transfer between unrelated write and read clocks.
Gray Code Pointer System: Binary-to-Gray and Gray-to-binary conversion for glitch-free full/empty detection across clock domains.
Dual-Port RAM: Efficient and safe memory architecture, including robust handling of empty reads.
Modular Architecture: All submodules (memory, pointers, synchronizers) are cleanly separated, easy to modify and extend.
Parameterization: Easily configure data width and FIFO depth via parameters.
Comprehensive Testbench: Deterministic, scenario-based verification with readable outputs for validation and debugging.
Best-Practice CDC Techniques: Implementation follows proven design methodologies from Cliff Cummings and leading hardware research.

##Modules and Design Approach
###top (top.v):
Integrates dual-port memory, write/read pointer controllers, two-flip-flop synchronizers, and Gray code logic.
All internal modules defined within the same file for easy synthesis.

###tb (tb.v):
Drives clocks, resets, data input. Stimulates overflow, underflow, sequential and interleaved boundary cases.
No randomization—deterministic, readable data patterns for waveform and text validation.

##Block Diagram

<img width="1280" height="656" alt="Async_FIFO" src="https://github.com/user-attachments/assets/25e9a847-2741-4a94-a88d-18c57d73c6cb" />

##Simulation
<img width="1025" height="423" alt="Screenshot 2025-11-12 012904" src="https://github.com/user-attachments/assets/21530bd0-d100-4d6c-b318-dd56eda092e5" />
