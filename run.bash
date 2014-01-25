#!/bin/bash

echo -e "=== clang -O3:"
time ./bin_test_c_clang > /dev/null
echo -e "\n=== gcc -O3:"
time ./bin_test_c_gcc > /dev/null
echo -e "\n=== mono C#:"
time ./bin_test_cs > /dev/null
echo -e "\n=== D:"
time ./bin_test_d > /dev/null
echo -e "\n=== Go gc:"
time ./bin_test_go_gc > /dev/null
echo -e "\n=== Go gccgo -O3:"
time ./bin_test_go_gccgo > /dev/null
echo -e "\n=== Rust:"
time ./bin_test_rs > /dev/null
