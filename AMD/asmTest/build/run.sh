#!/bin/sh
cd ../source/assembly
./asm.sh Cijk_Ailk_Bjlk_DB_MT096x032x08_K1_NLCA03_NLCB01_TT06_04_USFGRO0_WG16_08_01 -mcpu=gfx906
cd -
echo && echo "################################################################################" && echo "# Configuring CMake for Client" && echo "################################################################################"
cmake -DTensile_RUNTIME_LANGUAGE=HIP -DTensile_CLIENT_BENCHMARK=ON  -DCMAKE_BUILD_TYPE=Release -DTensile_MERGE_FILES=ON ../source
echo && echo "################################################################################" && echo "# Building Client" && echo "################################################################################"
cmake --build . --config Release -- -j 8
/opt/rocm/bin/rocm-smi -d 0 --setfan 255 --setsclk 7
sleep 1
/opt/rocm/bin/rocm-smi -d 0 -a
./client --platform-idx 0 --device-idx 0 --init-alpha 2 --init-beta 0 --init-c 3 --init-a 3 --init-b 3 --print-valids 0 --print-max 4 --num-benchmarks 1 --num-elements-to-validate 0 --num-enqueues-per-sync 1 --num-syncs-per-benchmark 2 --use-gpu-timer 1 --sleep-percent 200
ERR=$?
/opt/rocm/bin/rocm-smi -d 0 --resetclocks
/opt/rocm/bin/rocm-smi -d 0 --setfan 50
exit $ERR
