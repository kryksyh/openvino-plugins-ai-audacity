#!/bin/bash

source `dirname ${BASH_SOURCE[0]}`/config.sh

brew install opencl-clhpp-headers

cd $SOURCE_PATH
rm *tar.gz
mv *audacity* audacity
mv *whisper* whisper.cpp
cd ..

cp -r mod-openvino $SOURCE_PATH/audacity/modules
sed -i '' 's/set( FOLDERS/set( FOLDERS\n   mod-openvino/' $SOURCE_PATH/audacity/modules/CMakeLists.txt
mkdir -p $PACKAGE_PATH

cd $PACKAGE_PATH
wget https://storage.openvinotoolkit.org/repositories/openvino/packages/2024.0/macos/m_openvino_toolkit_macos_11_0_2024.0.0.14509.34caeefd078_arm64.tgz
tar xvf m_openvino_toolkit_macos_11_0_2024.0.0.14509.34caeefd078_arm64.tgz
source m_openvino_toolkit_macos_11_0_2024.0.0.14509.34caeefd078_arm64/setupvars.sh

wget https://download.pytorch.org/libtorch/cpu/libtorch-macos-arm64-2.2.2.zip
unzip libtorch-macos-arm64-2.2.2.zip
export LIBTORCH_ROOTDIR=$PACKAGE_PATH/libtorch

mkdir -p $BUILD_PATH/whisper
cd $BUILD_PATH/whisper
cmake $SOURCE_PATH/whisper.cpp -DWHISPER_OPENVINO=ON -DMACOS_ARCHITECTURE=arm64
make -j`sysctl -n hw.ncpu`

cmake --install . --config Release --prefix $PACKAGE_PATH/whisper
export WHISPERCPP_ROOTDIR=$PACKAGE_PATH/whisper
export LD_LIBRARY_PATH=${WHISPERCPP_ROOTDIR}/lib:$LD_LIBRARY_PATH

mkdir -p $BUILD_PATH/audacity
cd $BUILD_PATH/audacity


cmake -G "Unix Makefiles" \
    -D CMAKE_CXX_FLAGS="-I/opt/homebrew/opt/opencl-clhpp-headers/include" \
    -DMACOS_ARCHITECTURE=arm64 \
    $SOURCE_PATH/audacity -DCMAKE_BUILD_TYPE=Release
make -j`sysctl -n hw.ncpu`

cd $BUILD_PATH/..

mkdir -p mod-openvino-arm64/libs
mkdir -p mod-openvino-arm64/3rdparty/rbb

cp $BUILD_PATH/audacity/Release/Audacity.app/Contents/modules/mod-openvino.so \
    mod-openvino-arm64/libs

cp $PACKAGE_PATH/m_openvino_toolkit_macos_11_0_2024.0.0.14509.34caeefd078_arm64/runtime/lib/arm64/Release/*.so \
    mod-openvino-arm64/libs
cp $PACKAGE_PATH/m_openvino_toolkit_macos_11_0_2024.0.0.14509.34caeefd078_arm64/runtime/lib/arm64/Release/*.dylib \
    mod-openvino-arm64/libs
cp $PACKAGE_PATH/m_openvino_toolkit_macos_11_0_2024.0.0.14509.34caeefd078_arm64/runtime/3rdparty/tbb/lib/libtbb.12.dylib \
    mod-openvino-arm64/3rdparty/tbb

cp $PACKAGE_PATH/libtorch/lib/libc10.dylib \
    mod-openvino-arm64/libs
cp $PACKAGE_PATH/libtorch/lib/libtorch.dylib \
    mod-openvino-arm64/libs
cp $PACKAGE_PATH/libtorch/lib/libtorch_cpu.dylib \
    mod-openvino-arm64/libs

cp -P $PACKAGE_PATH/whisper/lib/*.dylib \
    mod-openvino-arm64/libs

xattr -cr mod-openvino-arm64/
