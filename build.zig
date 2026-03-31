const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.createModule(.{
        .root_source_file = b.path("src/module.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    // Emacs module header — check EMACS_INCLUDE_DIR env, then platform defaults
    if (b.graph.env_map.get("EMACS_INCLUDE_DIR")) |inc_dir| {
        mod.addSystemIncludePath(.{ .cwd_relative = inc_dir });
    } else {
        const resolved = target.result;
        if (resolved.os.tag == .macos) {
            mod.addSystemIncludePath(.{
                .cwd_relative = "/Applications/Emacs.app/Contents/Resources/include",
            });
        } else {
            // Linux: typical pkg-config path for emacs module headers.
            // Also try /usr/include which has emacs-module.h on most distros.
            mod.addSystemIncludePath(.{
                .cwd_relative = "/usr/include",
            });
        }
    }

    // libghostty-vt headers and static library (pre-built)
    // Build with: cd vendor/ghostty && zig build -Demit-lib-vt=true
    mod.addIncludePath(b.path("vendor/ghostty/zig-out/include"));
    mod.addObjectFile(b.path("vendor/ghostty/zig-out/lib/libghostty-vt.a"));

    // libghostty-vt bundled dependencies.
    // These are copied from .zig-cache to stable paths by build.sh.
    mod.addObjectFile(b.path("vendor/ghostty/zig-out/lib/libsimdutf.a"));
    mod.addObjectFile(b.path("vendor/ghostty/zig-out/lib/libhighway.a"));

    // libghostty-vt depends on libc++
    mod.linkSystemLibrary("c++", .{});

    const lib = b.addLibrary(.{
        .name = "ghostel-module",
        .linkage = .dynamic,
        .root_module = mod,
    });

    b.installArtifact(lib);

    // Copy the shared library to project root for easy Emacs loading.
    // Use the correct platform suffix.
    const resolved = target.result;
    const lib_name = if (resolved.os.tag == .macos)
        "../ghostel-module.dylib"
    else
        "../ghostel-module.so";
    const copy_step = b.addInstallFile(
        lib.getEmittedBin(),
        lib_name,
    );
    b.getInstallStep().dependOn(&copy_step.step);
}
