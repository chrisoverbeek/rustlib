use std::ffi::{CStr, CString};
use std::os::raw::c_char;

/// Core function that takes a string and returns a formatted message
pub fn format_message(input: &str) -> String {
    format!("Message received: [{}]", input)
}

/// FFI-compatible function that can be called from C++
/// Takes a C-style string pointer and returns a C-style string pointer
/// The caller is responsible for freeing the returned string using free_string
#[unsafe(no_mangle)]
pub extern "C" fn format_message_ffi(input: *const c_char) -> *mut c_char {
    if input.is_null() {
        return std::ptr::null_mut();
    }
    
    // Convert C string to Rust string
    let c_str = unsafe { CStr::from_ptr(input) };
    let input_str = match c_str.to_str() {
        Ok(s) => s,
        Err(_) => return std::ptr::null_mut(),
    };
    
    // Format the message
    let result = format_message(input_str);
    
    // Convert Rust string back to C string
    match CString::new(result) {
        Ok(c_string) => c_string.into_raw(),
        Err(_) => std::ptr::null_mut(),
    }
}

/// FFI function to free strings allocated by Rust
/// Must be called by C++ code to free strings returned by format_message_ffi
#[unsafe(no_mangle)]
pub extern "C" fn free_string(ptr: *mut c_char) {
    if !ptr.is_null() {
        unsafe {
            let _ = CString::from_raw(ptr);
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_format_message() {
        let result = format_message("Hello, World");
        assert_eq!(result, "Message received: [Hello, World]");
    }

    #[test]
    fn test_format_message_empty() {
        let result = format_message("");
        assert_eq!(result, "Message received: []");
    }

    #[test]
    fn test_format_message_special_chars() {
        let result = format_message("Test!@#$%");
        assert_eq!(result, "Message received: [Test!@#$%]");
    }

    #[test]
    fn test_ffi_function() {
        let input = CString::new("FFI Test").unwrap();
        let result_ptr = format_message_ffi(input.as_ptr());
        
        assert!(!result_ptr.is_null());
        
        let result_cstr = unsafe { CStr::from_ptr(result_ptr) };
        let result_str = result_cstr.to_str().unwrap();
        
        assert_eq!(result_str, "Message received: [FFI Test]");
        
        // Clean up
        free_string(result_ptr);
    }

    #[test]
    fn test_ffi_null_input() {
        let result_ptr = format_message_ffi(std::ptr::null());
        assert!(result_ptr.is_null());
    }
}
