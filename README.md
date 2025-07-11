This is a Zig package for the [Xiph.Org Foundation's](https://xiph.org) `libvorbis`. It provides `libvorbis`, `libvorbisfile`, and `libvorbisenc`.

Unnecessary files have been removed, and the build system has been replaced with `build.zig`.

This is for Zig 0.14.1, with `minimum_zig_version` set to the same value. The library will be updated only for STABLE Zig releases.

## Usage
### Adding to your project

1. Add this repository as a dependency in your `build.zig.zon`
```sh
zig fetch --save git+https://github.com/rplstr/vorbis.git
```

2. In your `build.zig`, add the dependency and link the artifacts you need.
```zig
// build.zig
const exe = b.addExecutable(...)

const vorbis = b.dependency("vorbis", .{
    .target = target,
    .optimize = optimize,
});

// this package exposes zig modules for vorbis, vorbisfile, and vorbisenc.
// simply add the one you need
// exe.addModule("vorbisfile", vorbis.module("vorbisfile"));
// exe.addModule("vorbisenc", vorbis.module("vorbisenc"));
// exe.addModule("vorbis", vorbis.module("vorbis"));

3. In your Zig code, you can then import and use it.
```zig
const vorbis = @import("vorbisfile");

pub fn main() !void {
    var vf: vorbis.OggVorbis_File = undefined;
    _ = &vf;
}
```
