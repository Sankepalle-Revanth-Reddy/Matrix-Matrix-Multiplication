# Matrix-Matrix-Multiplication

Hardware implementation of parameterized matrix-matrix multiplication (MMM) in SystemVerilog, with an AXI-Stream style interface and a randomized verification testbench.

## Overview

The design computes:

$$
C_{M \times N} = A_{M \times K} \times B_{K \times N}
$$

Key capabilities:
- Parameterized matrix sizes (`M`, `N`, `MAXK`)
- Parameterized datapath widths (`INW`, `OUTW`)
- AXI-Stream style handshake (`TVALID` / `TREADY`)
- Saturating arithmetic behavior in expected-reference model

## Repository Structure

```text
.
├── README.md
├── RTL/
│   ├── MMM.sv
│   ├── fifo_out.sv
│   ├── input_mems.sv
│   ├── mac.sv
│   └── mac_pipe.sv
└── TB/
		├── MMM_tb.sv
		└── test_helper.c
```

## RTL Modules

- `mac.sv`: multiply-accumulate unit
- `mac_pipe.sv`: pipelined MAC datapath stage(s)
- `input_mems.sv`: input matrix buffering and access logic
- `fifo_out.sv`: output FIFO and associated memory logic
- `MMM.sv`: top-level integration of MMM datapath and control

## Testbench

- `TB/MMM_tb.sv`: constrained-random top-level testbench
- `TB/test_helper.c`: DPI-C reference model function (`calcOutput`) used by testbench

The testbench expects a `params.sv` file (included by `MMM_tb.sv`) that defines parameter macros such as `INWVAL`, `OUTWVAL`, `MVAL`, `NVAL`, and `MAXKVAL`.

## Simulation (QuestaSim)

Run from the repository root.

1. Compile design and testbench files:

```bash
vlog -64 +acc TB/test_helper.c RTL/mac.sv RTL/mac_pipe.sv RTL/input_mems.sv RTL/fifo_out.sv RTL/MMM.sv TB/MMM_tb.sv
```

2. Run simulation in command-line mode:

```bash
vsim -64 -c MMM_tb -sv_seed random
```

3. Run simulation in GUI mode (optional):

```bash
vsim -64 MMM_tb -sv_seed random
```

## Technical Notes

- Intended parameter ranges:
	- `M >= 2`, `N >= 2`, `MAXK >= 2`
	- `2 <= INW <= 32`
	- `2*INW <= OUTW <= 64`
- Input stream carries matrix data and control (`K`, `new_A`) through sideband user bits.
- Throughput depends on handshake probabilities and internal pipeline/FIFO behavior.

## Typical Workflow

1. Update/generate `params.sv` for target dimensions and widths.
2. Run simulation and verify pass/fail behavior from `MMM_tb` logs.
3. Iterate on RTL for timing/throughput/resource tradeoffs.

## Tools

- Language: SystemVerilog (+ DPI-C for reference model)
- Simulator: QuestaSim/ModelSim-compatible flow
