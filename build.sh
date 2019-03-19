#!/bin/bash

sudo su -

# Install packages
yum -y install epel-release
yum -y install \
  boost-devel \
  cmake3 \
  flex \
  gcc \
  gcc-c++ \
  gnuplot \
  libXt-devel \
  make \
  mesa-libGL-devel \
  ncurses-devel \
  qt4-devel \
  qtwebkit-devel \
  readline-devel \
  zlib-devel

# Configure cmake alias
alternatives --install /usr/local/bin/cmake cmake /usr/bin/cmake3 10 \
    --slave /usr/local/bin/ctest ctest /usr/bin/ctest3 \
    --slave /usr/local/bin/cpack cpack /usr/bin/cpack3 \
    --slave /usr/local/bin/ccmake ccmake /usr/bin/ccmake3 \
    --family cmake

# Install Intel MPI 5.1
cd /tmp
curl -L http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/9278/l_mpi_p_5.1.3.223.tgz | tar xvz
cd /tmp/l_mpi_p_5.1.3.223
sed -i 's/ACCEPT_EULA=decline/ACCEPT_EULA=accept/' silent.cfg
sed -i 's/ACTIVATION_TYPE=exist_lic/ACTIVATION_TYPE=trial_lic/' silent.cfg
./install.sh -s silent.cfg
rm -rf /tmp/l_mpi_p_5.1.3.223
rm -f /tmp/l_mpi_p_5.1.3.223.tgz

# Download OpenFOAM-6 and ThirdParty-6 source
mkdir -p /opt/OpenFOAM
cd /opt/OpenFOAM
curl -L http://dl.openfoam.org/source/6 | tar xvz
curl -L http://dl.openfoam.org/third-party/6 | tar xvz
mv OpenFOAM-6-version-6 OpenFOAM-6
mv ThirdParty-6-version-6 ThirdParty-6
sed -i 's/FOAM_INST_DIR=$HOME\/\$WM_PROJECT/FOAM_INST_DIR=\/opt\/\$WM_PROJECT/' /opt/OpenFOAM/OpenFOAM-6/etc/bashrc
sed -i 's/export WM_MPLIB=SYSTEMOPENMPI/export WM_MPLIB=INTELMPI/' /opt/OpenFOAM/OpenFOAM-6/etc/bashrc

# Set environment variables
export MPI_ROOT=/opt/intel/compilers_and_libraries/linux/mpi
export PATH=$PATH:/usr/lib64/qt4/bin

# Build OpenFOAM and ThirdParty components
source /opt/intel/compilers_and_libraries/linux/bin/compilervars.sh intel64
source /opt/intel/compilers_and_libraries/linux/mpi/intel64/bin/mpivars.sh intel64
source /opt/OpenFOAM/OpenFOAM-6/etc/bashrc
/opt/OpenFOAM/ThirdParty-6/Allwmake
/opt/OpenFOAM/ThirdParty-6/makeParaView -config
sed -i '/DOCUMENTATION_DIR "\${CMAKE_CURRENT_SOURCE_DIR}\/doc"/d' /opt/OpenFOAM/ThirdParty-6/ParaView-5.4.0/Plugins/StreamLinesRepresentation/CMakeLists.txt
/opt/OpenFOAM/ThirdParty-6/makeParaView
wmRefresh
/opt/OpenFOAM/OpenFOAM-6/Allwmake -j

# Remove intermediate build files
cd /opt/OpenFOAM/ThirdParty-6
rm -rf build gcc-* gmp-* mpfr-* binutils-* boost* ParaView-* qt-*
find /opt/OpenFOAM/OpenFOAM-6/platforms/*/applications /opt/OpenFOAM/OpenFOAM-6/platforms/*/src -name "*.o" | xargs rm -f
find /opt/OpenFOAM/OpenFOAM-6/platforms/*/applications /opt/OpenFOAM/OpenFOAM-6/platforms/*/src -name "*.dep" | xargs rm -f
rm -rf /opt/OpenFOAM/OpenFOAM-6/platforms/*/applications /opt/OpenFOAM/OpenFOAM-6/platforms/*/src

# Create tar.gz archives
tar -zcvf openfoam6-paraview54-intelmpi51-centos7-hpc.tar.gz /opt/OpenFOAM/
tar -zcvf intelmpi51-centos7-hpc.tar.gz /opt/intel
