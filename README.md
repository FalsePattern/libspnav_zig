# libspnav

This is [libspnav](https://www.space-nav.com/),
packaged for [Zig](https://ziglang.org/).

## How to use it

First, update your `build.zig.zon`:

```
zig fetch --save https://github.com/FalsePattern/libspnav_zig/archive/refs/tags/1.2.0.tar.gz
```

Next, add this snippet to your `build.zig` script:

```zig
const spnav_dep = b.dependency("spnav", .{
    .target = target,
    .optimize = optimize,
});
your_compilation.linkLibrary(spnav_dep.artifact("spnav"));
```

This will provide libspnav as a static library to `your_compilation`.
