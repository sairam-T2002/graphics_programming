const glfw = @import("zglfw");

pub const EventType = enum {
    key_press,
    key_release,
    mouse_move,
    mouse_button_press,
    mouse_button_release,
    window_resize,
    window_close,
};

pub const Event = union(EventType) {
    key_press: struct { key: glfw.Key, mods: glfw.Mods },
    key_release: struct { key: glfw.Key },
    mouse_move: struct { x: f64, y: f64 },
    mouse_button_press: struct { button: glfw.MouseButton, mods: glfw.Mods },
    mouse_button_release: struct { button: glfw.MouseButton },
    window_resize: struct { width: i32, height: i32 },
    window_close: void,
};
