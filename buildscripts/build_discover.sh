#!/bin/sh

set -e

# Usage of this script.
usage() { echo "Usage: $(basename $0) [-c intel-impi/19.1.0.166|gnu-impi/9.2.0] [-b debug|release] [-m default|geos|gfs] [-n 1..12] [-t ON|OFF] [-x] [-v] [-h]" 1>&2; exit 1; }

# Set input argument defaults.
compiler="intel-impi/19.1.0.166"
build="debug"
clean="NO"
model="default"
nthreads=12
run_ctest="ON"
verbose="OFF"
account="g0613"
queue="debug"

# Set defaults for model paths.
geos_path="/gpfsm/dnb31/drholdaw/GEOSagcm-Jason-GH/Linux"
gfs_path="/dev/null"


# Parse input arguments.
while getopts 'v:t:xhc:b:m:n:' OPTION; do
  case "$OPTION" in
    b)
        build="$OPTARG"
        [[ "$build" == "debug" || \
           "$build" == "release" ]] || usage
        ;;
    c)
        compiler="$OPTARG"
        [[ "$compiler" == "gnu-impi/9.2.0" || \
           "$compiler" == "intel-impi/19.1.0.166" ]] || usage
        ;;
    m)
        model="$OPTARG"
        [[ "$model" == "default" || \
           "$model" == "geos" || \
           "$model" == "gfs" ]] || usage
        ;;
    n)
        n="$OPTARG"
        [[ $n -lt 1 || $n -gt 12 ]] && usage
        nthreads=$n
        ;;
    t)
        run_ctest="$OPTARG"
        [[ "$run_ctest" == "ON" || \
           "$run_ctest" == "OFF" ]] || usage
        ;;
    x)
        clean="YES"
        ;;
    v)
        VERBOSE="ON"
        ;;
    a)
        account="g0613"
        ;;
    q)
        queue="debug"
        ;;
    h|?)
        usage
        ;;
  esac
done
shift "$(($OPTIND -1))"

echo "Summary of input arguments:"
echo "   build = $build"
echo "compiler = $compiler"
echo "   model = $model"
echo " threads = $nthreads"
echo "   ctest = $run_ctest"
echo "   clean = $clean"
echo " verbose = $verbose"
echo " account = $account"
echo "   queue = $queue"
echo

# Load JEDI modules.
OPTPATH=/discover/swdev/jcsda/modules
MODLOAD=apps/jedi/$compiler

source $MODULESHOME/init/sh
module purge
export OPT=$OPTPATH
module use $OPT/modulefiles
module load $MODLOAD
module list

# Set up model specific paths for ecbuild.
case "$model" in
    "default" )
        MODEL=""
        ;;
    "geos" )
        read -p "Enter the path for GEOS model [default: $geos_path] " choice
        [[ $choice == "" ]] && FV3BASEDMODEL_PATH=$geos_path || FV3BASEDMODEL_PATH=$choice
        MODEL="-DFV3BASEDMODEL_PATH=$FV3BASEDMODEL_PATH -DBASELIBDIR=$BASELIBDIR"
        ;;
    "gfs" )
        read -p "Enter the path for GFS model [default: $gfs_path] " choice
        [[ $choice == "" ]] && FV3BASEDMODEL_PATH=$gfs_path || FV3BASEDMODEL_PATH=$choice
        MODEL="-DFV3BASEDMODEL_PATH=$FV3BASEDMODEL_PATH"
        ;;
esac

# Set up FV3JEDI specific paths.
compiler_build=`echo $compiler | tr / -`
FV3JEDI_BUILD="$PWD/build-$compiler_build-$build-$model"
cd $(dirname $0)/..
FV3JEDI_SRC=$(pwd)

case "$clean" in
    Y|YES ) rm -rf $FV3JEDI_BUILD ;;
    * ) ;;
esac

mkdir -p $FV3JEDI_BUILD && cd $FV3JEDI_BUILD

# Create module file for future sourcing
# --------------------------------------
file=modules.sh
cp ../buildscripts/$file ./
sed -i "s,OPTPATH,$OPTPATH,g" $file
sed -i "s,MODLOAD,$MODLOAD,g" $file

# Slurm job for running tests
# ---------------------------
file=ctest_slurm.sh
cp ../buildscripts/$file ./
sed -i "s,OPTPATH,$OPTPATH,g" $file
sed -i "s,MODLOAD,$MODLOAD,g" $file
sed -i "s,ACCOUNT,$account,g" $file
sed -i "s,QUEUE,$queue,g" $file
sed -i "s,BUILDDIR,$FV3JEDI_BUILD,g" $file

# Build
# -----
ecbuild --build=$build -DMPIEXEC=$MPIEXEC $MODEL $FV3JEDI_SRC
make update
cd fv3-jedi
make -j$nthreads
ctest -R fv3_get_ioda_test_data
cd ../

[[ $run_ctest == "ON" ]] && sbatch ctest_slurm.sh

exit 0
