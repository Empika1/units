const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    //library
    const libMod = b.createModule(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = "units",
        .root_module = libMod,
    });
    b.installArtifact(lib);

    //one executable for each example file in examples/
    var dir = try std.fs.cwd().openDir("examples", .{ .iterate = true });
    var it = dir.iterate();
    while (try it.next()) |file| {
        if (file.kind != .file) {
            continue;
        }
        const fileNameStem = std.fs.path.stem(file.name);
        const sourceName = try std.fs.path.join(b.allocator, &.{ "examples", file.name });
        defer b.allocator.free(sourceName);
        const exampleMod = b.createModule(.{
            .root_source_file = b.path(sourceName),
            .target = target,
            .optimize = optimize,
        });
        const exampleExe = b.addExecutable(.{
            .name = fileNameStem,
            .root_module = exampleMod,
        });
        b.installArtifact(exampleExe);
        exampleMod.addImport("units", libMod);

        const exampleRunCmd = b.addRunArtifact(exampleExe);
        exampleRunCmd.step.dependOn(b.getInstallStep());
        if (b.args) |args| {
            exampleRunCmd.addArgs(args);
        }
        const exampleRunName = try std.fmt.allocPrint(b.allocator, "run-{s}", .{fileNameStem});
        defer b.allocator.free(exampleRunName);
        const exampleDescName = try std.fmt.allocPrint(b.allocator, "run the example {s}", .{fileNameStem});
        defer b.allocator.free(exampleDescName);
        const exampleRunStep = b.step(exampleRunName, exampleDescName);
        exampleRunStep.dependOn(&exampleRunCmd.step);
    }
}
