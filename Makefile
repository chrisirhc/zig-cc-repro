# Makefile

CXX = g++
CXXFLAGS = -fPIC
LDFLAGS = -shared

all: main

mylib.so: mylib.cpp
	$(CXX) $(CXXFLAGS) $(LDFLAGS) -o mylib.so mylib.cpp

main: main.cpp mylib.so
	$(CXX) -o main main.cpp -L. -l :mylib.so

clean:
	rm -f main mylib.so
