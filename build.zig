const std = @import("std");
const fs = std.fs;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const shared = b.option(bool, "shared", "Build shared libraries") orelse false;
    const linkage = if (shared) std.builtin.LinkMode.dynamic else .static;

    const ogg_dep = b.dependency("libogg", .{
        .target = target,
        .optimize = optimize,
    });
    const ogg_lib = ogg_dep.artifact("ogg");

    const cflags = &[_][]const u8{
        "-D_REENTRANT",
        "-fsigned-char",
        "-D__NO_MATH_INLINES",
    };

    const libvorbis_module = b.createModule(.{
        .target = target,
        .optimize = optimize,
    });
    libvorbis_module.addIncludePath(b.path("include"));
    libvorbis_module.addIncludePath(b.path("lib"));
    libvorbis_module.addCSourceFiles(.{
        .files = &.{
            "lib/mdct.c",     "lib/smallft.c",    "lib/block.c",     "lib/envelope.c", "lib/window.c",
            "lib/lsp.c",      "lib/analysis.c",   "lib/synthesis.c", "lib/psy.c",      "lib/info.c",
            "lib/floor1.c",   "lib/floor0.c",     "lib/res0.c",      "lib/mapping0.c", "lib/registry.c",
            "lib/codebook.c", "lib/sharedbook.c", "lib/lookup.c",
        },
        .flags = cflags,
    });
    libvorbis_module.linkLibrary(ogg_lib);
    libvorbis_module.linkSystemLibrary("m", .{});

    const libvorbis = b.addLibrary(.{
        .name = "vorbis",
        .root_module = libvorbis_module,
        .version = .{ .major = 1, .minor = 3, .patch = 7 },
        .linkage = linkage,
    });
    libvorbis.installHeader(b.path("include/vorbis/codec.h"), "vorbis/codec.h");
    b.installArtifact(libvorbis);

    // libvorbisfile
    const libvorbisfile_module = b.createModule(.{
        .target = target,
        .optimize = optimize,
    });
    libvorbisfile_module.addIncludePath(b.path("include"));
    libvorbisfile_module.addCSourceFile(.{
        .file = b.path("lib/vorbisfile.c"),
        .flags = cflags,
    });
    libvorbisfile_module.linkLibrary(libvorbis);
    libvorbisfile_module.linkLibrary(ogg_lib);

    const libvorbisfile = b.addLibrary(.{
        .name = "vorbisfile",
        .root_module = libvorbisfile_module,
        .version = .{ .major = 1, .minor = 3, .patch = 7 },
        .linkage = linkage,
    });
    libvorbisfile.installHeader(b.path("include/vorbis/vorbisfile.h"), "vorbis/vorbisfile.h");
    b.installArtifact(libvorbisfile);

    // libvorbisenc
    const libvorbisenc_module = b.createModule(.{
        .target = target,
        .optimize = optimize,
    });
    libvorbisenc_module.addIncludePath(b.path("include"));
    libvorbisenc_module.addIncludePath(b.path("lib"));
    libvorbisenc_module.addCSourceFile(.{
        .file = b.path("lib/vorbisenc.c"),
        .flags = cflags,
    });
    libvorbisenc_module.linkLibrary(libvorbis);
    libvorbisenc_module.linkLibrary(ogg_lib);

    const libvorbisenc = b.addLibrary(.{
        .name = "vorbisenc",
        .root_module = libvorbisenc_module,
        .version = .{ .major = 1, .minor = 3, .patch = 7 },
        .linkage = linkage,
    });
    libvorbisenc.installHeader(b.path("include/vorbis/vorbisenc.h"), "vorbis/vorbisenc.h");
    b.installArtifact(libvorbisenc);

    // codec.h
    const vorbis_zig = b.addTranslateC(.{
        .root_source_file = b.path("include/vorbis/codec.h"),
        .target = target,
        .optimize = optimize,
    });
    vorbis_zig.addIncludePath(b.path("include"));

    const vorbis_module = b.addModule("vorbis", .{
        .root_source_file = vorbis_zig.getOutput(),
    });
    vorbis_module.linkLibrary(libvorbis);

    // vorbisfile.h
    const vorbisfile_zig = b.addTranslateC(.{
        .root_source_file = b.path("include/vorbis/vorbisfile.h"),
        .target = target,
        .optimize = optimize,
    });
    vorbisfile_zig.addIncludePath(b.path("include"));

    const vorbisfile_module = b.addModule("vorbisfile", .{
        .root_source_file = vorbisfile_zig.getOutput(),
    });
    vorbisfile_module.linkLibrary(libvorbisfile);

    // vorbisenc.h
    const vorbisenc_zig = b.addTranslateC(.{
        .root_source_file = b.path("include/vorbis/vorbisenc.h"),
        .target = target,
        .optimize = optimize,
    });
    vorbisenc_zig.addIncludePath(b.path("include"));

    const vorbisenc_module = b.addModule("vorbisenc", .{
        .root_source_file = vorbisenc_zig.getOutput(),
    });
    vorbisenc_module.linkLibrary(libvorbisenc);

    const install_pkg_config = b.option(bool, "pkg-config", "Install pkg-config files") orelse true;
    if (install_pkg_config) {
        installPkgConfig(b, libvorbis, "vorbis", "vorbis is a general purpose audio and music encoding format.", "ogg");
        installPkgConfig(b, libvorbisenc, "vorbisenc", "vorbisenc is a library that provides a high-level API for Vorbis encoding.", "vorbis");
        installPkgConfig(b, libvorbisfile, "vorbisfile", "vorbisfile is a library that provides a high-level API for decoding and playing Ogg Vorbis files.", "vorbis");
    }
}

fn installPkgConfig(
    b: *std.Build,
    lib: *std.Build.Step.Compile,
    name: []const u8,
    description: []const u8,
    requires: []const u8,
) void {
    const version = lib.version orelse @panic("lib must have a version for pkg-config file");

    const pc_content = b.fmt(
        \\prefix={s}
        \\exec_prefix=${{prefix}}
        \\libdir={s}
        \\includedir={s}
        \\
        \\Name: {s}
        \\Description: {s}
        \\Version: {d}.{d}.{d}
        \\Requires: {s}
        \\Conflicts:
        \\Libs: -L${{libdir}} -l{s}
        \\Cflags: -I${{includedir}}
        \\
    , .{
        b.install_prefix,
        b.lib_dir,
        b.h_dir,
        name,
        description,
        version.major,
        version.minor,
        version.patch,
        requires,
        name,
    });

    const pc_file_name = b.fmt("{s}.pc", .{name});
    const pc_file_path = b.fmt("pkgconfig/{s}", .{pc_file_name});
    const pc_file_step = b.addWriteFile(pc_file_path, pc_content);

    b.getInstallStep().dependOn(&b.addInstallFileWithDir(
        pc_file_step.getDirectory().path(b, pc_file_path),
        .lib,
        b.pathJoin(&.{ "pkgconfig", pc_file_name }),
    ).step);
}
