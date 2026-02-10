script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

export PROTEUS_DIR=$script_dir
export INCLUDEOS_PREFIX=$script_dir/funky-unikernel/IncludeOS_install
export BITSTREAM_DIR=/share/felix/bitstreams
export CC=clang
export CXX=clang++

source /opt/xilinx/xrt/setup.sh
source /tools/Intel/intelFPGA_pro/20.2/hld/init_opencl.sh
