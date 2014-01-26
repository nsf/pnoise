#!/bin/bash

echo -e "=== clang -O3:"
time ./bin_test_c_clang > /dev/null
echo -e "\n=== gcc -O3:"
time ./bin_test_c_gcc > /dev/null
echo -e "\n=== mono C#:"
time ./bin_test_cs > /dev/null
echo -e "\n=== D (dmd):"
time ./bin_test_d_dmd > /dev/null
echo -e "\n=== D (ldc2):"
time ./bin_test_d_ldc > /dev/null
echo -e "\n=== D (gdc):"
time ./bin_test_d_gdc > /dev/null
echo -e "\n=== Go gc:"
time ./bin_test_go_gc > /dev/null
echo -e "\n=== Go gccgo -O3:"
time ./bin_test_go_gccgo > /dev/null
echo -e "\n=== Rust:"
time ./bin_test_rs > /dev/null
