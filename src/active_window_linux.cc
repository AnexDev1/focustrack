#include <iostream>
#include <string>
#include <vector>
#include <memory>
#include <cstring>
#include <X11/Xlib.h>
#include <X11/Xatom.h>

// Custom deleter for XFree
void XFreeDeleter(void* p) {
    if (p) {
        XFree(p);
    }
}

using XUniquePtr = std::unique_ptr<unsigned char, decltype(&XFreeDeleter)>;

std::string get_property(Display* disp, Window win, Atom atom) {
    Atom actual_type;
    int actual_format;
    unsigned long nitems, bytes_after;
    unsigned char* prop_data = nullptr;

    if (XGetWindowProperty(disp, win, atom, 0, 1024, False, AnyPropertyType,
                           &actual_type, &actual_format, &nitems, &bytes_after,
                           &prop_data) == Success && prop_data) {
        XUniquePtr p(prop_data, &XFreeDeleter);
        if (actual_type == XA_STRING || actual_type == XInternAtom(disp, "UTF8_STRING", False)) {
            return std::string(reinterpret_cast<char*>(p.get()));
        }
    }
    return "";
}

// Get the actual focused window, traversing up if needed
Window get_focused_window(Display* disp, Window root, Atom net_active_atom) {
    // First try _NET_ACTIVE_WINDOW
    Atom actual_type;
    int actual_format;
    unsigned long nitems, bytes_after;
    unsigned char* prop = nullptr;

    if (XGetWindowProperty(disp, root, net_active_atom, 0, 1, False, XA_WINDOW,
                           &actual_type, &actual_format, &nitems, &bytes_after,
                           &prop) == Success && prop) {
        Window win = *reinterpret_cast<Window*>(prop);
        XFree(prop);
        if (win != 0) {
            return win;
        }
    }
    
    // Fallback: use XGetInputFocus
    Window focused_win;
    int revert_to;
    XGetInputFocus(disp, &focused_win, &revert_to);
    
    return focused_win;
}

int main() {
    Display* disp = XOpenDisplay(nullptr);
    if (!disp) {
        std::cerr << "Cannot open display" << std::endl;
        return 1;
    }

    Window root = DefaultRootWindow(disp);
    Atom net_active_window_atom = XInternAtom(disp, "_NET_ACTIVE_WINDOW", False);
    Atom net_wm_name_atom = XInternAtom(disp, "_NET_WM_NAME", False);
    Atom wm_name_atom = XInternAtom(disp, "WM_NAME", False);
    Atom wm_class_atom = XInternAtom(disp, "WM_CLASS", False);

    Window active_win = get_focused_window(disp, root, net_active_window_atom);
    
    if (active_win == 0 || active_win == root) {
        XCloseDisplay(disp);
        std::cerr << "No active window found" << std::endl;
        return 1;
    }

    // Try to get window title from _NET_WM_NAME first, then WM_NAME
    std::string window_title = get_property(disp, active_win, net_wm_name_atom);
    if (window_title.empty()) {
        window_title = get_property(disp, active_win, wm_name_atom);
    }

    // Get WM_CLASS
    std::string window_class;
    Atom actual_type;
    int actual_format;
    unsigned long nitems, bytes_after;
    unsigned char* prop_data = nullptr;

    if (XGetWindowProperty(disp, active_win, wm_class_atom, 0, 1024, False, AnyPropertyType,
                           &actual_type, &actual_format, &nitems, &bytes_after,
                           &prop_data) == Success && prop_data) {
        // WM_CLASS contains two null-terminated strings
        // Format: "instance\0class\0"
        char* class_data = reinterpret_cast<char*>(prop_data);
        size_t len = nitems;
        
        // Find the first null terminator
        size_t first_null = 0;
        while (first_null < len && class_data[first_null] != '\0') {
            first_null++;
        }
        
        // Get the instance name (first string)
        std::string instance_name(class_data, first_null);
        
        // Get the class name (second string) if available
        std::string class_name;
        if (first_null + 1 < len) {
            size_t second_start = first_null + 1;
            size_t second_null = second_start;
            while (second_null < len && class_data[second_null] != '\0') {
                second_null++;
            }
            class_name = std::string(class_data + second_start, second_null - second_start);
        }
        
        // Prefer class name, fallback to instance name
        window_class = !class_name.empty() ? class_name : instance_name;
        
        XFree(prop_data);
    }

    // Use window_class as app name, with smarter fallbacks
    std::string app_name;
    if (!window_class.empty()) {
        app_name = window_class;
    } else if (!window_title.empty()) {
        // Try to extract app name from title (e.g., "Something - Telegram" -> "Telegram")
        size_t dash_pos = window_title.rfind(" - ");
        size_t pipe_pos = window_title.rfind(" | ");
        if (dash_pos != std::string::npos && dash_pos + 3 < window_title.length()) {
            app_name = window_title.substr(dash_pos + 3);
        } else if (pipe_pos != std::string::npos && pipe_pos + 3 < window_title.length()) {
            app_name = window_title.substr(pipe_pos + 3);
        } else {
            // Use first part of title or whole title
            size_t first_space = window_title.find(' ');
            if (first_space != std::string::npos && first_space > 0) {
                app_name = window_title.substr(0, first_space);
            } else {
                app_name = window_title;
            }
        }
    } else {
        app_name = "Unknown";
    }

    std::cout << "App: " << app_name << std::endl;
    std::cout << "Title: " << window_title << std::endl;

    XCloseDisplay(disp);
    return 0;
}
