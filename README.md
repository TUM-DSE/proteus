# Proteus: Heterogeneous FPGA Virtualization

This is the code for the paper "Proteus: Heterogeneous FPGA Virtualization" by Felix Gust, Shu Anzai, Charalampos Mainas, Atsushi Koshiba, and Pramod Bhatotia published at EuroSys'26.

This repo consists of the following submodules:

- funky-monitor: Proteus Hypervisor
- funky-unikernel: Proteus OS, applications, and benchmark scripts
- funky-rosetta: Rosetta benchmark suite
- vitis-accel-examples: Vitis Accel Examples applications
- proteus-eval: Data, scripts, and plots for the Proteus evaluation

If you want to build Proteus on your own machine, start from the beginning. If you want to build Proteus on our servers, start with [Setup](#setup).

## System requirements

We tested Proteus on Ubuntu 20.04 x86-64 with Linux kernel version 5.8.0-55. We used a total of four FPGA boards: 2x AMD/Xilinx Alveo U50 (8 GiB HBM) and 2x Alveo U280 (8 GiB HBM + 32 GiB DDR4). All four boards are only required for evaluation "5.5 Multi-task Workloads and Scalability". For the other experiments one U50 and one U280 are sufficient.

## Build Proteus

### Install dependencies

Install basic packages:

```bash
sudo apt-get update && sudo apt-get install -y build-essential clang cmake nasm git curl opencl-headers
```

Install XRT:

```bash
curl https://download.amd.com/opendownload/xlnx/xrt_202320.2.16.204_20.04-amd64-xrt.deb -o ~/Downloads/xrt_202320.2.16.204_20.04-amd64-xrt.deb
```

```bash
sudo apt-get install -y ~/Downloads/xrt_202320.2.16.204_20.04-amd64-xrt.deb
```

If you want to recreate Figure 10 from the paper, download the Intel FPGA SDK for OpenCL Pro Edition version 20.2 for Linux from [altera.com](https://www.altera.com/downloads/add-development-tools/fpga-sdk-opencl-pro-edition-software-version-20-2). Follow the installation instructions and install the software in `/tools/Intel/intelFPGA_pro/20.2`. All other experiments can be run without the Intel tools.

### Setup

Clone this repository and submodules:

```bash
git clone --recurse-submodules https://github.com/TUM-DSE/proteus.git
```

Setup environment:

```bash
cd proteus && source env.sh
```

Prepare directories:

```bash
cd funky-unikernel && mkdir $INCLUDEOS_PREFIX && mkdir build && cd build
```

Setup tap device `tap100`:

```bash
$PROTEUS_DIR/funky-unikernel/funky-scripts/setup_tap_device.sh
```

### Build hypervisor and unikernel

In `funky-unikernel/build` directory:

```bash
cmake .. -DCMAKE_INSTALL_PREFIX=${INCLUDEOS_PREFIX}
```

Build dependencies, including [funky-monitor](https://github.com/TUM-DSE/funky-monitor/tree/proteus):

```bash
make PrecompiledLibraries
```

Build IncludeOS:

```bash
make -j $(nproc)
```

Install in `INCLUDEOS_PREFIX`:

```bash
make install
```

### Build applications

Build native applications:

```bash
cd $PROTEUS_DIR/funky-unikernel/funky-scripts/evaluation && ./build_bench_native.sh
```

Build Proteus applications:

```bash
./build_bench.sh
```

## Run benchmarks

The benchmark scripts expect the bitstreams in `$BITSTREAM_DIR/{vitis-accel-examples,rosetta}/<app>/<fpga>/bitstream`. On our servers, this directory already contains the bitstreams.

### Simple example application

Go to the helloworld example:

```bash
cd $PROTEUS_DIR/funky-unikernel/examples/Vitis_Accel_Examples/ocl_kernels/cl_helloworld
```

We provide an execution script. To run the helloworld example on the U280 with our precompiled bitstream, run:

```bash
./execute.sh -t u280 -i $BITSTREAM_DIR/vitis-accel-examples/cl_helloworld/u280-fast/bitstream -a 'funcycl-app a'
```

The output should look like this:

```txt
INFO: u280 is used as the FPGA type.
INFO: /share/felix/bitstreams/vitis-accel-examples/cl_helloworld/u280-fast/bitstream is used as the bitstream.
[DEBUG-UKVM] handle_cmdarg(): Set FPGA type to u280
ukvm-bin: build/funkycl-app: Warning: phdr[1] requests WRITE and EXEC permissions
time elapsed before launching vCPU: 0.004356946 s
     [ Kernel ] Printing memory map
                * 0x0000000500 - 0x0000005fff,  22.750_KiB (100.0 %) solo5
                * 0x0000006000 - 0x0000008fff,  12.000_KiB (100.0 %) Statman
                * 0x000000a000 - 0x000009fbff, 599.000_KiB (100.0 %) Stack
                * 0x0000200000 - 0x00006174f8,   4.091_MiB (100.0 %) ELF
                * 0x00006174f9 - 0x0000681fff, 426.757_KiB (100.0 %) Pre-heap
                * 0x0000682000 - 0x00ff9e7fff,   3.988_GiB (0.0   %) Dynamic memory
     [ Kernel ] Booted at monotonic_ns=8231715 walltime_ns=1770291923590743835
      [ Solo5 ] Looking for solo5 devices
     [ Kernel ] Initializing plugins
     [ Kernel ] Running service constructors
--------------------------------------------------------------------------------
================================================================================
 IncludeOS funky-v0.3.1-152-g818e16396 (x86_64 / 64-bit)
 +--> Running [ hello world in Vitis Accel Examples ]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Found Platform
Platform Name: Funk
Trying to program device[0]: Funky FPGA
UKVM: set up fpga...
Device[0]: program successful!
UKVM: using bitstream /tmp/bitstream_0.ukvm
[worker_thr] FPGA_load overhead breakdown...
worker_init[s],fpga_reconf[s],load_fpga[s]
0.265587449,4.230104306,0.000000138
app_name,kernel_input_data_size,kernel_output_data_size,iterations,time_cpu,data_to_fpga_time_ocl,kernel_time_ocl,data_to_host_time_ocl
cl_helloworld,524288,262144,1000,0.854881795,0.075257124,0.597264412,0.033754254
Result =
TEST PASSED
MSG_KILLWORKER request has been received.
UKVM: confirm the worker thread is going to be destroyed.
UKVM: waiting for worker thread to terminate.
       [ main ] returned with status 0
     [ Kernel ] Stopping service
     [ Kernel ] Powering off
```

The `-a` flag specifies the arguments for the user application. The application `funkycl-app` is in the `build` directory and expects the bitstream file as an argument. As Proteus transparently handles bitstreams, we simply give it the dummy argument `a`.

To list additional options for the execute script, run:

```bash
./execute.sh -h
```

To get more information about the bitstream, look at the info file:

```bash
less $BITSTREAM_DIR/vitis-accel-examples/cl_helloworld/u280-fast/vector_addition.link.xclbin.info
```

For example, you can see the kernel clock frequency:

```txt
Achieved Freq:  490.1 MHz
```

### Evaluation 1: portability

Go to the directory with the evaluation scripts. We assume this is your current working directory in the remaining sections:

```bash
cd $PROTEUS_DIR/funky-unikernel/funky-scripts/evaluation
```

Get the kernel clock frequencies for U50 and U280:

```bash
./get_bitstream_freq.sh | tee frequencies.csv
```

The frequencies for the Intel Stratix 10 have been manually collected from compilation reports.

Get the total lines of code (LoC) of the applications:

```bash
cd portability && ./count_loc.sh $PROTEUS_DIR/vitis-accel-examples/ocl_kernels $PROTEUS_DIR/funky-rosetta
```

The LoC are shown in the file `loc_<date>_<time>/loc.csv`.

Get the LoC of FPGA-related API calls:

```bash
./count_ocl_loc.sh | tee ocl-loc.csv
```

### Evaluation 2: performance

#### End-to-end performance

Measure the time of native applications with each FPGA configuration and 10 runs per application:

```bash
./measure_time_native.sh 10 u50-fast u280-fast u280-ddr-fast arria10-fast
```

You can also use bitstreams with lower frequency (200/300 MHz) by using `-slow` instead of `-fast` for the U50 and U280. These were used for Figure 2 in the "Background and Motivation" section.

To run the same applications in Proteus:

```bash
./measure_time.sh 10 u50-fast u280-fast u280-ddr-fast arria10-fast
```

You can expect each script to run for at least six hours. The times are saved in the csv files in `time_(native_)<date>_<time>`.

#### Overhead breakdown

Get average overheads of 10 iterations:

```bash
./overheads.py 10
```

The times are save in `time_overheads_<date>_<time>/overheads.csv`.

### Evaluation 3: memory virtualization

#### Data placement optimization

Get average times of 10 iterations:

```bash
./mem_benchmarks.py 10
```

The times are saved in the csv files in `time_mem_<date>_<time>`.

#### Memory oversubscription

Get average times of 10 iterations:

```bash
./oversub.py 10
```

The times are saved in the csv files in `time_oversub_<date>_<time>`.

#### Migration

Get average overheads of 10 iterations:

```bash
cd state_management && ./run_benchmark.sh fpga_state_oh 10 && ./run_benchmark.sh vm_state_oh 10 && ./run_benchmark.sh migration_oh 10
```

The overheads are saved in the csv files in `{fpga_state,vm_state,migration}_oh_<date>_<time>`.

### Evaluation 4: scheduling

#### Scoring algorithm

This is part of [Create tables and plots](#create-tables-and-plots).

#### Multi-task workloads and scalability

Coming soon...

### Troubleshooting

#### ln: failed to create symbolic link '/tmp/bitstream_0.ukvm'

The execute script symlinks the bitstream to `/tmp/bitstream_0.ukvm` for the hypervisor. If this symlink exists and you do not have permissions to change it, you get this error. Try removing it:

```bash
sudo rm /tmp/bitstream_0.ukvm
```

## Create tables and plots

Go to proteus-eval and create a python venv:

```bash
cd $PROTEUS_DIR/proteus-eval && python3 -m venv .venv
```

Enter the venv:

```bash
source .venv/bin/activate
```

Install python packages:

```bash
pip install -r requirements.txt
```

Run all scripts:

```bash
./scripts/run-all.sh
```

The scripts create csv files and plots. If you ran the above command within the last five minutes, you can use the following command to see all files that have been modified by the scripts:

```bash
find . -newermt "5 minutes ago" -ls
```
