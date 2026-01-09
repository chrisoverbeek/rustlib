#include <iostream>
#include "../rustlib.h"

int main() {
    // Example 1: Simple message formatting
    const char* input1 = "Hello from C++";
    char* result1 = format_message_ffi(input1);
    
    if (result1 != nullptr) {
        std::cout << "Result 1: " << result1 << std::endl;
        free_string(result1);
    } else {
        std::cerr << "Error: format_message_ffi returned null" << std::endl;
    }
    
    // Example 2: Another message
    const char* input2 = "Rust FFI is working!";
    char* result2 = format_message_ffi(input2);
    
    if (result2 != nullptr) {
        std::cout << "Result 2: " << result2 << std::endl;
        free_string(result2);
    }
    
    // Example 3: Empty string
    const char* input3 = "";
    char* result3 = format_message_ffi(input3);
    
    if (result3 != nullptr) {
        std::cout << "Result 3: " << result3 << std::endl;
        free_string(result3);
    }
    
    return 0;
}
