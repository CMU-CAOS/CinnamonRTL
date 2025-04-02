# Cinnamon: A Framework for Scale-Out Encrypted AI

This repository contains the RTL for the Cinnamon Accelerator based on the ASPLOS 2025 paper [Cinnamon: A Framework for scale out Encrytped AI](https://dl.acm.org/doi/10.1145/3669940.3707260).

Checkout out the other repositories in the Cinnamon Framework
- [Cinnamon Emulator]()
- [Cinnamon Architectural Simulator]()
- [Cinnamon Accelerator RTL]()


## To build and test the Cinnamon Accelerator RTL,

- Install a RTL simulator. Currently VCS, Xcelium, Verilator and Modelsim are supported.

- Run `make SIM=vcs/xcelium/verilator/modelsim` to run all tests.

- Run `make SIM=xcelium DEBUG=1` to run test with waveform viewer.
