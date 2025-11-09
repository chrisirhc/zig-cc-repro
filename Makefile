# Makefile

CXX = g++
# Success with 0.13
# CXX = ./zig/zig-linux-x86_64-0.13.0/zig c++
# Fails with 0.14 and above
# CXX = ./zig/zig-linux-x86_64-0.14.0/zig c++
# CXX = ./zig/zig-linux-x86_64-0.15.0-dev.64+2a4e06bcb/zig c++
CXXFLAGS = -fPIC
LDFLAGS = -shared

all: main

mylib.so: mylib.cpp
	$(CXX) $(CXXFLAGS) $(LDFLAGS) -o libmylib.so mylib.cpp

main: main.cpp mylib.so
	$(CXX) -o main main.cpp -L. -lmylib

clean:
	rm -f main mylib.so
