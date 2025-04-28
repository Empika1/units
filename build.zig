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
    const examples = .{
        "examples/basic.zig",
        "examples/errors.zig",
        "examples/physics.zig",
        "examples/readmeCode.zig",
    };
    inline for (examples) |example| {
        const fileNameStem = comptime std.fs.path.stem(example);
        const exampleMod = b.createModule(.{
            .root_source_file = b.path(example),
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
        const exampleRunName = std.fmt.comptimePrint("run-{s}", .{fileNameStem});
        const exampleDescName = std.fmt.comptimePrint("run the example {s}", .{fileNameStem});
        const exampleRunStep = b.step(exampleRunName, exampleDescName);
        exampleRunStep.dependOn(&exampleRunCmd.step);
    }
}
