# I2C Multi-Bus Controller (I2CMB) Complete Layered Verification Testbench

A comprehensive, multi-phase hardware verification suite designed to thoroughly validate the OpenCores I2C Multiple Bus Controller (I2CMB) IP Core. This repository consolidates a step-by-step evolutionary migration from a basic flat testbench interface up to a complete SystemVerilog layered verification environment capable of constraint-driven random testing, precise functional coverage tracking, and complete regression closure.

## Verification Architecture Evolution

The testbench structure transitions smoothly across distinct project phases included in this repository:

1. **Phase 1: Basic Interface & Hardware Tasks** Established the core connection parameters between the Wishbone bus (`wb_if`) and the I2C bus (`i2c_if`) interfaces with the Design Under Test (DUT). Developed underlying transactional driver mechanics including `wait_for_i2c_transfer` (write/read cycles) and dynamic `provide_read_data` task handlers.
   
2. **Phase 2: Layered Testbench Architecture** Migrated infrastructure into a fully modular, layered environment utilizing the custom foundation class library (`ncsu_pkg`). Built distinct abstract components including a dedicated test wrapper (`i2cmb_test`), environmental configuration handlers, generator arrays (`i2cmb_generator`), independent monitor layers (`wb_monitor`, `i2c_monitor`), an active prediction module (`i2cmb_predictor`), and an automated transaction comparator (`i2cmb_scoreboard`).

3. **Phase 3: Formal Test Plan Specification & Coverage Linking** Constructed a structured verification Test Plan outlining over 20 unique verification target elements (isolating register-level accesses and multi-bus state hazards). Implemented corresponding SystemVerilog `covergroups`, parameterized `coverpoints`, and `cross` coverage criteria to systematically map runtime metrics against the structural XML test plan map within the Siemens/Questa UCDB database engine.

4. **Phase 4: Constraint-Driven Random Testing & Regression Closure** Developed specialized random transaction constraints and complex directed testing scenarios to exercise edge cases and hit remaining test plan points. Configured an automated shell-driven automation framework (`regress.sh`) that triggers concurrent randomized simulations, captures isolated coverage databases, and merges them into a definitive cumulative coverage summary for final analysis.

---

## Test & Simulation Verification Flow

Across all developmental phases, the infrastructure enforces a structured verification data flow mapping write and read scenarios down to the physical interfaces:

- **Targeted Diagnostic Transfers**: Verifies sequential multi-byte write streams (e.g., 32 incrementing data chunks traveling from Wishbone down onto the physical I2C lines).
- **Dynamic Bus Response**: Exercises bidirectional interface handshakes by triggering sudden read loops, forcing the internal monitor pipelines to validate data consistency on the fly.
- **Alternating Interleaved Stress Scenarios**: Floods bus arbiters with tightly interleaved read/write boundaries to identify potential structural deadlocks or state discrepancies within the DUT.
- **Scoreboard Validation**: Automatically cross-checks physical transaction observations across both interfaces, flagging structural discrepancies or illegal bus states directly in the runtime transcripts without cluttering output summaries.

---

## Getting Started

### Prerequisites
- Linux/Unix Compute Cluster Environment.
- **Siemens Questa Sim / ModelSim** simulation environment.
- Standard Shell Utilities (`bash`, `tar`).

### Installation & Execution Guide

Each project phase maintains its own workspace directory under the master layout. To launch a localized simulation target, traverse into the desired simulation boundary and use the provided Makefiles:

```bash
cd ece745_projects/proj_4/sim
make debug
```
To execute a full automated test plan regression pass, compile concurrent randomized sequences, and evaluate coverage merging metrics:
```bash
./regress.sh
```
