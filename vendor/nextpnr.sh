#!/usr/bin/env bash

pip install apycula --target $PWD/apicula

mkdir -p $PWD/nextpnr/build \
 && cd $PWD/nextpnr \
 && curl -fsSL https://codeload.github.com/YosysHQ/nextpnr/tar.gz/main | tar xzf - --strip-components=1 \
 && cd build \
 && cmake .. \
   -DARCH=himbaechel \
   -DHIMBAECHEL_UARCH=gowin \
   -DHIMBAECHEL_GOWIN_DEVICES=GW1N-9C \
   -DBUILD_GUI=OFF \
   -DBUILD_PYTHON=ON \
   -DUSE_OPENMP=ON \
   -DBoost_NO_BOOST_CMAKE=ON \
   -DBOOST_ROOT=/usr \
   -DEigen3_DIR=/usr/share/eigen3/cmake \
 && make -j $(nproc) \
 && make DESTDIR=$PWD/nextpnr install
