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

At our chair, we have the following setup:

- momiji.dse.in.tum.de: 2x U280
- hinoki.dse.in.tum.de: 1x U50
- sakura.dse.in.tum.de: 1x U50

Set the following environment variable on the server with 2x U280:

```bash
export PROTEUS_FPGAS="u280-fast u280-ddr-fast"
```

and on the servers with 1x U50:

```bash
export PROTEUS_FPGAS="u50-fast"
```

The following setup has to be completed on all servers. We note when an experiment should be run on a specific server.

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

Setup tap devices (`tap0`, `tap1`, `tap100`) and remove old Proteus files in /tmp:

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

Make sure the monitor is executable:

```bash
chmod +x $INCLUDEOS_PREFIX/includeos/x86_64/lib/ukvm-bin
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

### Simple example application (momiji)

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

### Evaluation 1: portability (any server)

Go to the directory with the evaluation scripts. We assume this is your current working directory in the remaining sections:

```bash
cd $PROTEUS_DIR/funky-unikernel/funky-scripts/evaluation
```

Get the kernel clock frequencies for U50 and U280:

```bash
./get_bitstream_freq.sh | tee frequencies.csv
```

The frequencies for the Intel Stratix 10 have been collected from compilation reports manually.

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

For the setup at our chair, run each of the following commands on momiji and hinoki.

#### End-to-end performance

Measure the time of native applications with each FPGA configuration and 10 runs per application:

```bash
./measure_time_native.sh 10 $PROTEUS_FPGAS arria10-fast
```

You can also use bitstreams with lower frequency (200/300 MHz) by using `-slow` instead of `-fast` for `PROTEUS_FPGAS`. These were used for Figure 2 in the "Background and Motivation" section.

To run the same applications in Proteus:

```bash
./measure_time.sh 10 $PROTEUS_FPGAS arria10-fast
```

You can expect each script to run for at least six hours. The times are saved in the csv files in `time_(native_)<date>_<time>`.

#### Overhead breakdown

Get average overheads of 10 iterations:

```bash
./overheads.py 10
```

The times are save in `time_overheads_<date>_<time>/overheads.csv`.

### Evaluation 3: memory virtualization

Run the first two experiments on momiji.

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

Run this on momiji and hinoki.

Get average overheads of 10 iterations:

```bash
cd state_management && ./run_benchmark.sh fpga_state_oh 10 && ./run_benchmark.sh vm_state_oh 10 && ./run_benchmark.sh migration_oh 10
```

The overheads are saved in the csv files in `{fpga_state,vm_state,migration}_oh_<date>_<time>`.

### Evaluation 4: scheduling

#### Scoring algorithm

This is part of [Create tables and plots](#create-tables-and-plots).

#### Multi-task workloads and scalability

For these experiments we use three servers with the following IP addresses:

- sakura: 131.159.102.5
- hinoki: 131.159.102.6
- momiji: 131.159.102.19

Create the required binaries and scripts in `sched_sim` on all servers:

```bash
./prepare_multitask.sh
```

##### Single U50

On hinoki:

```bash
stdbuf -oL ./sched_bins/1_fpga_u50/primary | tee single-u50.txt
```

On sakura:

```bash
UKVM_BIN=$INCLUDEOS_PREFIX/includeos/x86_64/lib/ukvm-bin sched_bins/1_fpga_u50/daemon -i 131.159.102.6 -p 4217
```

On hinoki in a second shell:

```bash
bash sched_bins/1_fpga_u50/deploy_script.sh
```

##### Single U280

On hinoki:

```bash
stdbuf -oL sched_bins/1_fpga_u280/primary | tee single-u280.txt
```

On momiji:

```bash
UKVM_BIN=$INCLUDEOS_PREFIX/includeos/x86_64/lib/ukvm-bin sched_bins/1_fpga_u280/daemon -i 131.159.102.6 -p 4217
```

On hinoki in a second shell:

```bash
bash sched_bins/1_fpga_u280/deploy_script.sh
```

##### 2 U50

On hinoki:

```bash
stdbuf -oL sched_bins/2_fpga_50/primary | tee 2-u50.txt
```

On hinoki in a second shell:

```bash
UKVM_BIN=$INCLUDEOS_PREFIX/includeos/x86_64/lib/ukvm-bin sched_bins/2_fpga_50/daemon -i 131.159.102.6 -p 4217
```

On sakura:

```bash
UKVM_BIN=$INCLUDEOS_PREFIX/includeos/x86_64/lib/ukvm-bin sched_bins/2_fpga_50/daemon -i 131.159.102.6 -p 4217
```

On hinoki in a third shell:

```bash
bash sched_bins/2_fpga_50/deploy_script.sh
```

##### 2 U280

On momiji:

```bash
stdbuf -oL sched_bins/2_fpga_280/primary | tee 2-u280.txt
```

On momiji in a second shell:

```bash
UKVM_BIN=$INCLUDEOS_PREFIX/includeos/x86_64/lib/ukvm-bin sched_bins/2_fpga_280/daemon -i 131.159.102.19 -p 4217 -t 0
```

On momiji in a third shell:

```bash
UKVM_BIN=sched_bins/ukvm-bin-patched sched_bins/2_fpga_280/daemon -i 131.159.102.19 -p 4217 -t 1
```

On momiji in a fourth shell:

```bash
bash sched_bins/2_fpga_280/deploy_script.sh
```

##### 4 FPGAs

On hinoki:

```bash
stdbuf -oL sched_bins/4_fpga/primary | tee 4-fpgas.txt
```

On hinoki in a second shell:

```bash
UKVM_BIN=$INCLUDEOS_PREFIX/includeos/x86_64/lib/ukvm-bin sched_bins/4_fpga/daemon_u50 -i 131.159.102.6 -p 4217
```

On sakura:

```bash
UKVM_BIN=$INCLUDEOS_PREFIX/includeos/x86_64/lib/ukvm-bin sched_bins/4_fpga/daemon_u50 -i 131.159.102.6 -p 4217
```

On momiji:

```bash
UKVM_BIN=$INCLUDEOS_PREFIX/includeos/x86_64/lib/ukvm-bin sched_bins/4_fpga/daemon -i 131.159.102.6 -p 4217 -t 0
```

On momiji in a second shell:

```bash
UKVM_BIN=sched_bins/ukvm-bin-patched sched_bins/4_fpga/daemon -i 131.159.102.6 -p 4217 -t 1
```

On hinoki in a third shell:

```bash
bash sched_bins/4_fpga/deploy_script.sh
```

Finally, you can get the times on momiji and hinoki:

```bash
grep "200 tasks" *.txt
```

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
