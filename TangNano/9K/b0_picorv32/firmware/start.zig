const build_options = @import("build_options");

export fn _start() callconv(.naked) noreturn {
    asm volatile (
        \\li sp, 0x400
        \\lui s0, 0x20000
        \\.Lloop:
        \\sw zero, 0(s0)
        \\li t0, %[delay]
        \\.Ldelay1:
        \\addi t0, t0, -1
        \\bne t0, zero, .Ldelay1
        \\li t1, 7
        \\sw t1, 0(s0)
        \\li t0, %[delay]
        \\.Ldelay2:
        \\addi t0, t0, -1
        \\bne t0, zero, .Ldelay2
        \\j .Lloop
        :
        : [delay] "i" (build_options.delay),
        : .{ .memory = true }
    );
}
