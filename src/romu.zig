const std = @import("std");
const rand = std.rand;
const math = std.math;
const Random = rand.Random;
const rotl = math.rotl;
const testing = std.testing;
const assert = std.debug.assert;

const multiplier64 = 0xd3833e804f4c574b;
const multiplier32 = 0xc61d672b;

pub const Quad = Impl(quad);
pub const Trio = Impl(trio);
pub const Duo = Impl(duo);
pub const DuoJr = Impl(duoJr);
pub const Quad32 = Impl(quad32);
pub const Trio32 = Impl(trio32);
pub const Mono32 = Impl(mono32);

const quad = struct {
    w: u64,
    x: u64,
    y: u64,
    z: u64,

    const Int = u64;

    fn init(seed: u64) quad {
        var sm = rand.SplitMix64.init(seed);
        return .{
            .w = sm.next(),
            .x = sm.next(),
            .y = sm.next(),
            .z = sm.next(),
        };
    }

    inline fn next(self: *quad) u64 {
        const wp = self.w;
        const xp = self.x;
        const yp = self.y;
        const zp = self.z;

        self.w = multiplier64 *% zp;
        self.x = zp +% rotl(u64, wp, 52);
        self.y = yp -% xp;
        self.z = yp +% wp;
        self.z = rotl(u64, self.z, 19);

        return xp;
    }
};

const trio = struct {
    x: u64,
    y: u64,
    z: u64,

    const Int = u64;

    fn init(seed: u64) trio {
        var sm = rand.SplitMix64.init(seed);
        return .{
            .x = sm.next(),
            .y = sm.next(),
            .z = sm.next(),
        };
    }

    inline fn next(self: *trio) u64 {
        const xp = self.x;
        const yp = self.y;
        const zp = self.z;

        self.x = multiplier64 *% zp;
        self.y = yp -% xp;
        self.y = rotl(u64, self.y, 12);
        self.z = zp -% yp;
        self.z = rotl(u64, self.z, 44);

        return xp;
    }
};

const duo = struct {
    x: u64,
    y: u64,

    const Int = u64;

    fn init(seed: u64) duo {
        var sm = rand.SplitMix64.init(seed);
        return .{
            .x = sm.next(),
            .y = sm.next(),
        };
    }

    inline fn next(self: *duo) u64 {
        const xp = self.x;

        self.x = multiplier64 *% self.y;
        self.y = rotl(u64, self.y, 36) + rotl(u64, self.y, 15) - xp;

        return xp;
    }
};

const duoJr = struct {
    x: u64,
    y: u64,

    const Int = u64;

    fn init(seed: u64) duoJr {
        var sm = rand.SplitMix64.init(seed);
        return .{
            .x = sm.next(),
            .y = sm.next(),
        };
    }

    inline fn next(self: *duo) u64 {
        const xp = self.x;

        self.x = multiplier64 *% self.y;
        self.y = self.y -% xp;
        self.y = rotl(u64, self.y, 27);

        return xp;
    }
};

// Generator to extend 32-bit seed values into longer sequences.
const SplitMix32 = struct {
    s: u32,

    pub fn init(seed: u32) SplitMix32 {
        return SplitMix32{ .s = seed };
    }

    pub fn next(self: *SplitMix32) u64 {
        self.s +%= 0x9e3779b9;

        var z = self.s;
        z = (z ^ (z >> 16)) *% 0x85ebca6b;
        z = (z ^ (z >> 13)) *% 0xc2b2ae35;
        return z ^ (z >> 16);
    }
};

const quad32 = struct {
    w: u32,
    x: u32,
    y: u32,
    z: u32,

    const Int = u32;

    fn init(seed: u32) quad32 {
        var sm = rand.SplitMix64.init(seed);
        return .{
            .w = sm.next(),
            .x = sm.next(),
            .y = sm.next(),
            .z = sm.next(),
        };
    }

    inline fn next(self: *quad32) u32 {
        const wp = self.w;
        const xp = self.x;
        const yp = self.y;
        const zp = self.z;

        self.w = multiplier64 *% zp;
        self.x = zp +% rotl(u32, wp, 26);
        self.y = yp -% xp;
        self.z = yp +% wp;
        self.z = rotl(u32, self.z, 9);

        return xp;
    }
};

const trio32 = struct {
    x: u32,
    y: u32,
    z: u32,

    fn init(seed: u32) trio32 {
        var sm = rand.SplitMix32.init(seed);
        return trio32{
            .x = sm.next(),
            .y = sm.next(),
            .z = sm.next(),
        };
    }

    inline fn next(self: *trio32) u32 {
        const xp = self.x;
        const yp = self.y;
        const zp = self.z;

        self.x = multiplier32 *% zp;
        self.y = yp -% xp;
        self.y = rotl(u32, self.y, 6);
        self.z = zp -% yp;
        self.z = rotl(u32, self.z, 22);

        return xp;
    }
};

const mono32 = struct {
    x: u32,

    const Int = u32;

    fn init(seed: u32) mono32 {
        return mono32{ .x = (seed & 0x1fffffff) +% 0x44f619d0 };
    }

    inline fn next(self: *mono32) u32 {
        const result = self.x >> 16;

        self.x = self.x *% 0xd747a13b;
        self.x = rotl(u32, self.x, 12);

        return result;
    }
};

fn Impl(comptime hash: anytype) type {
    return struct {
        state: hash,

        const Hash = @This();

        pub fn init(seed: u64) Hash {
            return Hash{ .state = hash.init(seed) };
        }

        pub fn mix(self: *Hash) void {
            var i: usize = 0;
            while (i < 10) : (i += 1)
                _ = self.state.next();
        }

        pub fn random(self: *Hash) Random {
            return Random.init(self, fill);
        }

        pub fn fill(self: *Hash, buf: []u8) void {
            const size = comptime @sizeOf(hash.Int);
            var i: usize = 0;
            const aligned_len = buf.len - (buf.len & 7);

            // Complete 4/8 byte segments.
            while (i < aligned_len) : (i += size) {
                var n = self.state.next();
                comptime var j: usize = 0;
                inline while (j < size) : (j += 1) {
                    buf[i + j] = @truncate(u8, n);
                    n >>= 8;
                }
            }

            // Remaining. (cuts the stream)
            if (i != buf.len) {
                var n = self.state.next();
                while (i < buf.len) : (i += 1) {
                    buf[i] = @truncate(u8, n);
                    n >>= 8;
                }
            }
        }
    };
}

test "trio" {
    var rng = Trio{ .state = .{ .x = 42, .y = 42, .z = 42 } };
    rng.mix();
    {
        var copy = rng;
        try testing.expectEqual(copy.random().int(u8), 0xe2);
        try testing.expectEqual(copy.random().int(u8), 0x5c);
    }
    {
        var copy = rng;
        try testing.expectEqual(copy.random().int(u16), 0xfce2);
        try testing.expectEqual(copy.random().int(u16), 0xc55c);
    }
    {
        var copy = rng;
        try testing.expectEqual(copy.random().int(u32), 0x8364fce2);
        try testing.expectEqual(copy.random().int(u32), 0xd2c1c55c);
    }
    {
        var copy = rng;
        try testing.expectEqual(copy.random().int(u64), 0x2dc0b6dc8364fce2);
        try testing.expectEqual(copy.random().int(u64), 0x412c7339d2c1c55c);
    }
    {
        var copy = rng;
        try testing.expectEqual(copy.random().int(u64), 0x2dc0b6dc8364fce2);
        try testing.expectEqual(copy.random().int(u64), 0x412c7339d2c1c55c);
    }
    {
        var copy = rng;
        assert(math.fabs(copy.random().float(f32) - 0.51325965) < math.f32_epsilon);
        assert(math.fabs(copy.random().float(f32) - 0.8232692) < math.f32_epsilon);
    }
    {
        var copy = rng;
        assert(math.fabs(copy.random().float(f64) - 0.17872183688759324) < math.f64_epsilon);
        assert(math.fabs(copy.random().float(f64) - 0.2545845047159281) < math.f64_epsilon);
    }
    {
        var copy = rng;
        assert(copy.state.next() % 2 == 0);
        assert(copy.state.next() % 2 == 0);
        assert(copy.state.next() % 2 != 0);
    }
}
