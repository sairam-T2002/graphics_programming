const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("runtime", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
    });

    const zglfw_dep = b.dependency("zglfw", .{
        .target = target,
        .optimize = optimize,
    });

    const zopengl_dep = b.dependency("zopengl", .{});

    const zstbi_dep = b.dependency("zstbi", .{
        .target = target,
        .optimize = optimize,
    });

    const zlm_dep = b.dependency("zlm", .{
        .target = target,
        .optimize = optimize,
    });

    mod.addImport("zglfw", zglfw_dep.module("root"));
    mod.addImport("zopengl", zopengl_dep.module("root"));
    mod.addImport("zstbi", zstbi_dep.module("root"));
    mod.addImport("zlm", zlm_dep.module("zlm"));

    if (target.result.os.tag != .emscripten) {
        mod.linkLibrary(zglfw_dep.artifact("glfw"));
    }

    const exe = b.addExecutable(.{
        .name = "runtime",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "runtime", .module = mod },
            },
        }),
    });

    exe.root_module.addImport("zglfw", zglfw_dep.module("root"));
    exe.root_module.addImport("zopengl", zopengl_dep.module("root"));
    exe.root_module.addImport("zstbi", zstbi_dep.module("root"));
    exe.root_module.addImport("zlm", zlm_dep.module("zlm"));

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const mod_tests = b.addTest(.{
        .root_module = mod,
    });

    const run_mod_tests = b.addRunArtifact(mod_tests);

    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });

    const run_exe_tests = b.addRunArtifact(exe_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
    test_step.dependOn(&run_exe_tests.step);
}
