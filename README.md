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

If you want to recreate Figure 10 from the paper, download the Intel FPGA SDK for OpenCL Pro Edition version 20.2 for Linux from [here](https://www.altera.com/downloads/add-development-tools/fpga-sdk-opencl-pro-edition-software-version-20-2). Follow the installation instructions and install the software in `/tools/Intel/intelFPGA_pro/20.2`. All other experiments can be run without the Intel tools.

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
