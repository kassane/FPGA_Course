const std = @import("std");

pub fn build(b: *std.Build) void {
    const delay = b.option(u32, "delay", "Counter step delay iterations (default 50000)") orelse 50000;

    const target = b.resolveTargetQuery(.{
        .cpu_arch = .riscv32,
        .os_tag = .freestanding,
        .abi = .none,
        .cpu_model = .baseline,
        .cpu_features_sub = std.Target.riscv.featureSet(&.{ .c, .zca, .a, .f, .d, .zcf }),
    });

    const wf = b.addWriteFiles();
    const link_script = wf.add("link.ld",
        \\OUTPUT_ARCH(riscv)
        \\ENTRY(_start)
        \\SECTIONS {
        \\    . = 0x00000000;
        \\    .text   : { *(.text*) }
        \\    .rodata : { *(.rodata*) }
        \\    .data   : { *(.data*) }
        \\    .bss    : { *(.bss*) *(COMMON) }
        \\    . = ALIGN(4);
        \\    _end = .;
        \\    /DISCARD/ : { *(.eh_frame*) *(.eh_frame_hdr*) }
        \\}
    );

    const fw_mod = b.createModule(.{
        .target = target,
        .optimize = .ReleaseSmall,
        .strip = true,
        .stack_protector = false,
        .stack_check = false,
        .sanitize_c = .off,
        .no_builtin = true,
    });
    fw_mod.addCSourceFile(.{
        .file = b.path("start.S"),
        .flags = &.{},
    });
    fw_mod.addCSourceFile(.{
        .file = b.path("main.c"),
        .flags = &.{ "-ffreestanding", "-fno-builtin", b.fmt("-DDELAY={}", .{delay}) },
    });

    const exe = b.addExecutable(.{
        .name = "firmware",
        .root_module = fw_mod,
    });
    exe.bundle_compiler_rt = false;
    exe.setLinkerScript(link_script);

    const bin = exe.addObjCopy(.{ .format = .bin });

    const hex_cmd = b.addSystemCommand(&.{"python3"});
    hex_cmd.addFileArg(b.path("bin2hex.py"));
    hex_cmd.addFileArg(bin.getOutput());
    const hex = hex_cmd.captureStdOut(.{});

    const update = b.addUpdateSourceFiles();
    update.addCopyFileToSource(hex, "firmware.hex");
    b.getInstallStep().dependOn(&update.step);
}
