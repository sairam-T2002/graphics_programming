const std = @import("std");
const glfw = @import("zglfw");
const events = @import("events.zig");

pub const GraphicsApi = enum { opengl, webgpu, vulkan, d3d11, d3d12, metal };

pub const WindowConfig = struct {
    width: i32 = 800,
    height: i32 = 600,
    title: [:0]const u8 = "Zig Engine",
    resizable: bool = true,
    api: GraphicsApi = .opengl,
};

pub const Window = struct {
    handle: *glfw.Window,
    width: i32,
    height: i32,
    api: GraphicsApi,
    allocator: std.mem.Allocator,
    // A queue to store events until the main loop is ready to process them
    event_queue: std.ArrayList(events.Event),

    pub fn init(allocator: std.mem.Allocator, config: WindowConfig) !*Window {
        try glfw.init();

        switch (config.api) {
            .opengl => {
                glfw.windowHint(.client_api, .opengl_api);
                glfw.windowHint(.context_version_major, 4);
                glfw.windowHint(.context_version_minor, 0);
                glfw.windowHint(.opengl_profile, .opengl_core_profile);
            },
            else => glfw.windowHint(.client_api, .no_api),
        }

        glfw.windowHint(.resizable, config.resizable);

        const handle = try glfw.Window.create(config.width, config.height, config.title, null, null);

        if (config.api == .opengl) {
            glfw.makeContextCurrent(handle);
        }

        // We allocate the Window on the heap so its pointer remains stable for GLFW callbacks
        const self = try allocator.create(Window);
        self.* = .{
            .handle = handle,
            .width = config.width,
            .height = config.height,
            .api = config.api,
            .allocator = allocator,
            .event_queue = try std.ArrayList(events.Event).initCapacity(allocator, 16),
        };

        // Store this struct pointer inside GLFW handle
        handle.setUserPointer(self);

        // Register Callbacks
        _ = handle.setKeyCallback(keyCallback);
        _ = handle.setFramebufferSizeCallback(resizeCallback);
        _ = handle.setCursorPosCallback(cursorPosCallback);

        return self;
    }

    pub fn deinit(self: *Window, allocator: std.mem.Allocator) void {
        self.event_queue.deinit(allocator);
        self.handle.destroy();
        glfw.terminate();
        allocator.destroy(self);
    }

    pub fn pollEvents(_: *Window) void {
        glfw.pollEvents();
    }

    /// Returns the next event in the queue, or null if empty
    pub fn nextEvent(self: *Window) ?events.Event {
        if (self.event_queue.items.len == 0) return null;
        return self.event_queue.orderedRemove(0); // <-- Fixed here
    }

    pub fn isKeyDown(self: *Window, key: glfw.Key) bool {
        return self.handle.getKey(key) == .press;
    }

    pub fn shouldClose(self: *Window) bool {
        return self.handle.shouldClose();
    }
    pub fn swapBuffers(self: *Window) void {
        if (self.api == .opengl) self.handle.swapBuffers();
    }
};

// --- C-style Callback Bridges ---

fn keyCallback(window: *glfw.Window, key: glfw.Key, _: i32, action: glfw.Action, mods: glfw.Mods) callconv(.c) void {
    const self = window.getUserPointer(Window).?;
    if (action == .press) {
        self.event_queue.append(self.allocator, .{ .key_press = .{ .key = key, .mods = mods } }) catch {};
    } else if (action == .release) {
        self.event_queue.append(self.allocator, .{ .key_release = .{ .key = key } }) catch {};
    }
}

fn resizeCallback(window: *glfw.Window, width: i32, height: i32) callconv(.c) void {
    const self = window.getUserPointer(Window).?;
    self.width = width;
    self.height = height;
    self.event_queue.append(self.allocator, .{ .window_resize = .{ .width = width, .height = height } }) catch {};
}

fn cursorPosCallback(window: *glfw.Window, xpos: f64, ypos: f64) callconv(.c) void {
    const self = window.getUserPointer(Window).?;
    self.event_queue.append(self.allocator, .{ .mouse_move = .{ .x = xpos, .y = ypos } }) catch {};
}
