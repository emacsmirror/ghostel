const std = @import("std");

const vendored_emacs_module_dir = "include";

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const is_release = optimize != .Debug;
    const target_os = target.result.os.tag;
    const emacs_module_dir = resolveEmacsModuleDir(
        b.option([]const u8, "emacs_module_dir", "Directory containing emacs-module.h"),
    );
    const ghostty_dep = b.lazyDependency("ghostty", .{
        .target = target,
        .optimize = optimize,
        .@"emit-lib-vt" = true,
    }) orelse std.debug.panic(
        "ghostty dependency unavailable; initialize the vendor/ghostty submodule",
        .{},
    );

    const mod = b.createModule(.{
        .root_source_file = b.path("src/module.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .strip = if (is_release) true else null,
        .omit_frame_pointer = if (is_release) true else null,
    });
    addModuleIncludes(b, mod, emacs_module_dir);
    mod.linkLibrary(ghostty_dep.artifact("ghostty-vt-static"));

    const lib = b.addLibrary(.{
        .name = "ghostel-module",
        .linkage = .dynamic,
        .root_module = mod,
    });
    if (is_release) {
        lib.link_gc_sections = true;
        lib.link_function_sections = true;
        lib.link_data_sections = true;
        lib.dead_strip_dylibs = true;

        if (target_os == .linux) {
            lib.setVersionScript(b.path("symbols.map"));
        }
    }

    b.installArtifact(lib);

    const copy_step = b.addInstallFile(
        lib.getEmittedBin(),
        moduleOutputName(target_os),
    );
    b.getInstallStep().dependOn(&copy_step.step);

    const check_mod = b.createModule(.{
        .root_source_file = b.path("src/module.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    addModuleIncludes(b, check_mod, emacs_module_dir);

    const check_obj = b.addObject(.{
        .name = "ghostel-module-check",
        .root_module = check_mod,
    });

    const check = b.step("check", "Check that the module compiles (no linking)");
    check.dependOn(&check_obj.step);
}

fn addModuleIncludes(
    b: *std.Build,
    mod: *std.Build.Module,
    emacs_module_dir: std.Build.LazyPath,
) void {
    mod.addSystemIncludePath(emacs_module_dir);
    mod.addIncludePath(b.path("vendor/ghostty/include"));
}

fn resolveEmacsModuleDir(emacs_module_dir: ?[]const u8) std.Build.LazyPath {
    if (emacs_module_dir) |dir| {
        return .{ .cwd_relative = dir };
    }
    return .{ .cwd_relative = vendored_emacs_module_dir };
}

fn moduleOutputName(target_os: std.Target.Os.Tag) []const u8 {
    return switch (target_os) {
        .macos => "../ghostel-module.dylib",
        else => "../ghostel-module.so",
    };
}
