# Autocorrelator – VHDL Testbench

This repository contains a testbench for simulating the `CORR_ASP` autocorrelator module, using **ModelSim** as the simulation tool. The project is structured for use in the **CS701** environment, with `work` and `ip` libraries already precompiled.

## Prerequisites

- ModelSim (Intel FPGA Edition or compatible)
- CS701 project directory with compiled `work` and `ip` libraries

If any IP libraries are missing, you can recompile them with:

```bash
vcom -work ip <path_to_file>
```

# Simulation Steps

To run the autocorrelator testbench:

1. **Set ModelSim directory**

- Set the directory to CS701

2. **Compile Testbench Files**
   In ModelSim, compile the following VHDL files:

- test/CORR_ASP_test.vhd
- test/TestAdc.vhd
- test/TestCorrOut.vhd
- test/TestTopLevel.vhd

3. **Launch the Simulation**

- Run the simulation on the TestTopLevel testbench:

4. **Configure Signals**

- In the ADC component, import the channel_0 signal.
- In the CorrOut component, import the channel_0 signal.

5. **Run**

- Simulate for 1 ms to observe the autocorrelator's behavior.
