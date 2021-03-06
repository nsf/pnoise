#!/bin/bash
gcc -std=c99 -msse3 -mfpmath=sse -O3 -o bin_test_c_gcc test.c -lm
clang -std=c99 -march=native -msse3 -mfpmath=sse -O3 -o bin_test_c_clang test.c -lm
dmd -ofbin_test_d_dmd -O -boundscheck=off -inline -release test.d
ldc2 -O -ofbin_test_d_ldc test.d -release -mcpu=native -inline -boundscheck=off
gdc -Ofast -o bin_test_d_gdc test.d -frelease -finline -march=native -fno-bounds-check
gccgo -O3 -g -o bin_test_go_gccgo test.go
go build -o bin_test_go_gc test.go
rustc -O -o bin_test_rs test.rs
mcs -out:bin_test_cs test.cs
fsharpc -o bin_test_fs.exe -O test.fs
nim c -d:release --cc:gcc -o:bin_test_nim_gcc test.nim
nim c -d:release --cc:clang -o:bin_test_nim_clang test.nim
crystal build -o bin_test_cr --release test.cr
javac test.java
