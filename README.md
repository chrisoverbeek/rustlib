# rustlib
Simple rust library that we will attempt to call from C++ executable

## Overview
This is a Rust library that provides a simple string formatting function callable from C++. The library uses Foreign Function Interface (FFI) to enable C++ interoperability.

## Features
- Core function `format_message` that takes a string input and returns a formatted message
- FFI wrapper `format_message_ffi` that can be called from C++
- Memory management function `free_string` for proper cleanup

## Building the Library

```bash
cargo build --release
```

The compiled library will be available at:
- Linux: `target/release/librustlib.so`
- macOS: `target/release/librustlib.dylib`
- Windows: `target/release/rustlib.dll`

## Usage from C++

1. Include the header file `rustlib.h` in your C++ project
2. Link against the compiled Rust library
3. Call the FFI functions

### Example

```cpp
#include "rustlib.h"
#include <iostream>

int main() {
    const char* input = "Hello from C++";
    char* result = format_message_ffi(input);
    
    if (result != nullptr) {
        std::cout << result << std::endl;
        free_string(result);  // Important: free the allocated string
    }
    
    return 0;
}
```

### Compilation Example (Linux)

```bash
g++ -o myapp main.cpp -L./target/release -lrustlib -Wl,-rpath,./target/release
```

## API Reference

### `format_message_ffi`
```c
char* format_message_ffi(const char* input);
```
Takes a null-terminated C string and returns a formatted message. The returned string must be freed using `free_string()`.

**Parameters:**
- `input`: A null-terminated C string

**Returns:**
- A pointer to a newly allocated string containing the formatted message, or NULL on error

### `free_string`
```c
void free_string(char* ptr);
```
Frees a string allocated by the Rust library.

**Parameters:**
- `ptr`: A pointer to a string returned by `format_message_ffi()`

## Running Tests

```bash
cargo test
```

## License
See repository license.
