const std = @import("std");

pub fn build(b: *std.Build) void {
    const delay = b.option(u32, "delay", "LED blink delay iterations (default 5)") orelse 5;

    // baseline_rv32 includes C/A/F/D; subtract to pure RV32I (PicoRV32 has COMPRESSED_ISA=0)
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .riscv32,
        .os_tag = .freestanding,
        .abi = .none,
        .cpu_model = .baseline,
        .cpu_features_sub = std.Target.riscv.featureSet(&.{ .c, .zca, .a, .f, .d, .zcf }),
    });

    // Pass delay to Zig source via build options module
    const opts = b.addOptions();
    opts.addOption(u32, "delay", delay);

    // Generate link.ld in the build cache — no static file needed
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
        .root_source_file = b.path("start.zig"),
        .target = target,
        .optimize = .ReleaseSmall,
        .strip = true,
        .stack_protector = false,
        .stack_check = false,
        .no_builtin = true,
    });
    fw_mod.addImport("build_options", opts.createModule());

    const exe = b.addExecutable(.{
        .name = "firmware",
        .root_module = fw_mod,
    });
    exe.bundle_compiler_rt = false;
    exe.setLinkerScript(link_script);

    // ELF → raw binary
    const bin = exe.addObjCopy(.{ .format = .bin });

    // raw binary → Verilog $readmemh hex (one 32-bit LE word per line)
    const hex_cmd = b.addSystemCommand(&.{"python3"});
    hex_cmd.addFileArg(b.path("bin2hex.py"));
    hex_cmd.addFileArg(bin.getOutput());
    const hex = hex_cmd.captureStdOut(.{});

    // Write firmware.hex back into source tree alongside build.zig
    const update = b.addUpdateSourceFiles();
    update.addCopyFileToSource(hex, "firmware.hex");
    b.getInstallStep().dependOn(&update.step);
}
