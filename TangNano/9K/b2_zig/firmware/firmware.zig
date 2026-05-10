// Pure Zig firmware for PicoRV32 SoC — no C runtime, no libc.
// Entry point at 0x00000000. Stack is 1 KB BRAM top (0x400).
const build_options = @import("build_options");

const Gpio = struct {
    base: *volatile u32,

    pub fn write(self: Gpio, val: u3) void {
        self.base.* = @as(u32, val);
    }
};

// Knight-rider / cylon pattern (active-low: 0 = LED on, 1 = LED off)
const patterns = [_]u3{
    0b110, // R on
    0b101, // G on
    0b011, // B on
    0b101, // G on
    0b110, // R on
    0b111, // all off (pause)
    0b000, // all on  (flash)
    0b111, // all off (pause)
};

fn delay(n: u32) void {
    var i: u32 = n;
    while (i != 0) : (i -= 1) {
        asm volatile ("" ::: .{ .memory = true });
    }
}

// _start: naked entry — set SP then jump to run (no prologue/epilogue).
export fn _start() callconv(.naked) noreturn {
    asm volatile (
        \\li sp, 0x400
        \\j run
        ::: .{ .memory = true, .sp = true });
}

export fn run() noreturn {
    const gpio = Gpio{ .base = @ptrFromInt(0x20000000) };
    var idx: u3 = 0;
    while (true) {
        gpio.write(patterns[idx]);
        delay(build_options.delay);
        idx +%= 1; // wrapping u3: cycles 0..7 automatically
    }
}
