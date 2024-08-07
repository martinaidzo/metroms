#!/bin/bash
set -x
#export CICEVERSION=cice5.0
export CICEVERSION=cice5.1.2

NPX=1; NPY=1
NBX=1; NBY=1
if [ "${METROMS_MYHOST}" == "metlocal" ] || [ "${METROMS_MYHOST}" == "met_ppi" ]; then
    NPX=1  
    NPY=2
elif [ "${METROMS_MYHOST}" == "vilje" ] || \
	 [ "${METROMS_MYHOST}" == "fram" ] || \
	 [ "${METROMS_MYHOST}" == "nebula" ] || \
	 [ "${METROMS_MYHOST}" == "nebula2" ]
then
    NPX=1  
    NPY=2
fi

if [ $# -lt 1 ]
  then
  echo "Usage: $0 modelname <xcpu> <ycpu> <xblk> <yblk>"
  echo "<xcpu> <ycpu> and <xblk> <yblk> are optional arguments"
  exit
fi
export ROMS_APPLICATION=$1

if [ $# -ge 3 ]; then
    NPX=$2
    NPY=$3
fi

if [ $# -ge 5 ]; then
    NBX=$4
    NBY=$5
fi

echo Number of processors: "NPX = $NPX, NPY = $NPY"
echo Number of blocks per processor in each direction "NBX = $NBX, NBY = $NBY"

#if [ $# -ne 2 ]
#then
#    echo "Usage: $0 NPX NPY"
#    exit 1
#fi 

if [ ! -d ${METROMS_TMPDIR} ] ; then
    echo "METROMS_TMPDIR not defined, set environment variable METROMS_TMPDIR"
    exit 
fi
if [ ! -d ${METROMS_BASEDIR} ] ; then
    echo "METROMS_BASEDIR not defined, set environment variable METROMS_TMPDIR"
    exit 
fi

# Build CICE
export CICE_DIR=${METROMS_TMPDIR}/$ROMS_APPLICATION/cice
mkdir -p $CICE_DIR/rundir
cd ${METROMS_TMPDIR}/$ROMS_APPLICATION
# Unpack standard source files
echo $PWD
tar -xvf ${METROMS_BASEDIR}/static_libs/$CICEVERSION.tar.gz
cd $CICE_DIR

export MCT_INCDIR=${METROMS_TMPDIR}/MCT/include
export MCT_LIBDIR=${METROMS_TMPDIR}/MCT/lib


# Copy modified source files
#mkdir -p ${tup}/tmproms/cice
mkdir -p $CICE_DIR/input_templates/$ROMS_APPLICATION/
cp -a ${METROMS_BASEDIR}/apps/common/modified_src/$CICEVERSION/* $CICE_DIR
cp -av ${METROMS_APPDIR}/$ROMS_APPLICATION/cice_input_grid/* $CICE_DIR/input_templates/$ROMS_APPLICATION/
# Remove old binaries
rm -f $CICE_DIR/rundir/cice

echo $PWD
./comp_ice $ROMS_APPLICATION $NPX $NPY $NBX $NBY

# Not working on nebula2 yet due to problems in the linking of stand-alone cice
if [ ! "${METROMS_MYHOST}" == "nebula2" ]; then

    # Test if compilation and linking was successfull
    if [ ! -f $CICE_DIR/rundir/cice ]; then
	echo "$CICE_DIR/rundir/cice not found"
	echo "Error with compilation "
	exit -1
    fi
fi

# Build a library (for use in the ROMS build)
cd $CICE_DIR/rundir/compile
ar rcv libcice.a *.o

rm -f $CICE_DIR/rundir/cice

#cd $CICE_DIR


set +x
