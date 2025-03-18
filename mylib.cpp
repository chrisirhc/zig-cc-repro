#include <iostream>

extern "C" void hello() {
    std::cout << "Hello from the shared library!" << std::endl;
}
