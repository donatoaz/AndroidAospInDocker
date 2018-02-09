#!/bin/bash

# we're not using compiler caching
# prebuilts/misc/linux-x86/ccache/ccache -M 50G

# load android env variables
source build/envsetup.sh

# lunch the tootlchain for arm-eng (1)
lunch 1

# we don't need to rebuild everything
# make installclean
# make clean
# time make -j3

# enter bongiovi directory
cd external/bongiovi

# build the module
# time mm -B

# run new build script
./new_build --lib-dps-path . --prebuilt-dps -d nexus_5
