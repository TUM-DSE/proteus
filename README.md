# Proteus: Heterogeneous FPGA Virtualization

This repo consists of the following submodules:

- funky-monitor: Proteus Hypervisor
- funky-unikernel: Proteus OS, applications, and benchmark scripts
- funky-rosetta: Rosetta benchmark suite
- vitis-accel-examples: Vitis Accel Examples applications
- proteus-eval: Data, scripts, and plots for the Proteus evaluation

If you want to build Proteus on your own machine, start from the beginning. If you want to build Proteus on our server (momiji.dse.in.tum.de), start with [Setup](#setup).

## System requirements

We tested Proteus on Ubuntu 20.04 x86-64 with Linux kernel version 5.8.0-55. We used a total of four FPGA boards: 2x AMD/Xilinx Alveo U50 (8 GiB HBM) and 2x Alveo U280 (8 GiB HBM + 32 GiB DDR4). All four boards are only required for evaluation "5.5 Multi-task Workloads and Scalability", for other experiments one U50 and one U280 are sufficient.

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
git clone --recurse-submodules git@github.com:TUM-DSE/proteus.git
```

Set the `PROTEUS_DIR` environment variable:

```bash
cd proteus && export PROTEUS_DIR=$PWD
```

Setup environment:

```bash
source /opt/xilinx/xrt/setup.sh && source /tools/Intel/intelFPGA_pro/20.2/hld/init_opencl.sh
```

```bash
cd funky-unikernel && mkdir IncludeOS_install && export INCLUDEOS_PREFIX=$PWD/IncludeOS_install
```

```bash
export CC=clang && export CXX=clang++
```

```bash
mkdir build && cd build
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

Set the environment variable for the bitstream directory. On our severs, this is:

```bash
export BITSTREAM_DIR=/share/felix/bitstreams
```

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

### Troubleshooting

#### ln: failed to create symbolic link '/tmp/bitstream_0.ukvm'

The execute script symlinks the bitstream to `/tmp/bitstream_0.ukvm` for the hypervisor. If this symlink exists and you do not have permissions to change it, you get this error. Try removing it:

```bash
sudo rm /tmp/bitstream_0.ukvm
```

## Create tables and plots

Coming soon.
