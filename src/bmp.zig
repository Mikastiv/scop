const std = @import("std");
const mem = std.mem;
const Image = @import("Image.zig");

const CompressionType = enum(u32) {
    rgb = 0,
    rle8 = 1,
    rle4 = 2,
    bitfields = 3,
    jpeg = 4,
    png = 5,
    alpha_bitfields = 6,
};

fn fourCC(comptime a: u8, comptime b: u8, comptime c: u8, comptime d: u8) u32 {
    return (@as(u32, a) << 24) | (@as(u32, b) << 16) | (@as(u32, c) << 8) | @as(u32, d);
}

const ColorSpace = enum(u32) {
    calibrated_rgb = 0,
    srgb = fourCC('s', 'R', 'G', 'B'),
    windows = fourCC('W', 'i', 'n', ' '),
    profile_linked = fourCC('L', 'I', 'N', 'K'),
    profile_embedded = fourCC('M', 'B', 'E', 'D'),
};

const bmp_identifier = "BM";

const FileHeader = extern struct {
    identifier: [2]u8,
    filesize: u32 align(1),
    reserved: u32 align(1),
    image_offset: u32 align(1),
};

const BmpHeader = extern struct {
    header_size: u32,
    width: i32,
    height: i32,
    n_color_planes: u16,
    bpp: u16,
    compression_type: CompressionType,
    image_size: u32,
    x_pixels_per_meter: u32,
    y_pixels_per_meter: u32,
    n_colors: u32,
    n_important_colors: u32,
    red_mask: u32,
    green_mask: u32,
    blue_mask: u32,
    alpha_mask: u32,
    color_space: ColorSpace,
};

const BufferedReader = std.io.BufferedReader(8 * 1024, std.io.StreamSource.Reader);

const BmpReader = struct {
    const Self = @This();

    buffered_reader: BufferedReader,

    fn init(stream: *std.io.StreamSource) Self {
        return .{ .buffered_reader = .{ .unbuffered_reader = stream.reader() } };
    }

    fn readFn(self: *const anyopaque, buffer: []u8) anyerror!usize {
        const ptr: *Self = @constCast(@alignCast(@ptrCast(self)));
        return ptr.buffered_reader.read(buffer);
    }

    fn reader(self: *Self) std.io.AnyReader {
        return .{
            .context = @ptrCast(self),
            .readFn = readFn,
        };
    }
};

pub fn load(allocator: mem.Allocator, filename: []const u8, flip_vertically: bool) !Image {
    std.debug.assert(mem.endsWith(u8, filename, ".bmp"));

    const image = try std.fs.cwd().openFile(filename, .{});
    defer image.close();
    var stream = std.io.StreamSource{ .file = image };
    var bmp_reader = BmpReader.init(&stream);
    var reader = bmp_reader.reader();

    const file_header: FileHeader = try reader.readStruct(FileHeader);
    const bmp_header: BmpHeader = try reader.readStruct(BmpHeader);

    if (bmp_header.header_size < @sizeOf(BmpHeader))
        return error.UnsupportedHeaderVersion;

    if (!mem.eql(u8, &file_header.identifier, bmp_identifier))
        return error.InvalidBmpFile;

    if (bmp_header.bpp != 32 and bmp_header.bpp != 24)
        return error.UnsupportedBppFormat;

    if (bmp_header.n_colors != 0)
        return error.UnsupportedColorPalette;

    if (bmp_header.color_space != .srgb and bmp_header.color_space != .windows)
        return error.UnsupportedColorSpace;

    var flipped = bmp_header.height < 0;

    const alloc_size = bmp_header.width * 4 * bmp_header.height;
    var pixels = try allocator.alloc(u32, @as(usize, @intCast(alloc_size)));
    var out_image = Image{
        .allocator = allocator,
        .pixels = pixels,
        .width = @intCast(bmp_header.width),
        .height = if (flipped) @intCast(-bmp_header.height) else @intCast(bmp_header.height),
        .bpp = bmp_header.bpp,
    };

    var y: u32 = if (flipped) out_image.height - 1 else 0;
    if (flip_vertically) flipped = !flipped;
    const increment = if (flipped) @as(i32, -1) else @as(i32, 1);

    switch (bmp_header.compression_type) {
        .rgb => {
            for (0..out_image.height) |_| {
                const scanline = y * out_image.width;
                var x: u32 = 0;
                for (0..out_image.width) |_| {
                    const b = try reader.readByte();
                    const g = try reader.readByte();
                    const r = try reader.readByte();
                    const a = 0xFF;
                    const pixel: u32 = (@as(u32, a) << 24) | (@as(u32, b) << 16) | (@as(u32, g) << 8) | @as(u32, r);
                    out_image.pixels[scanline + x] = pixel;
                    x += 1;
                }
                y += @bitCast(increment);
            }
        },
        .bitfields => {
            const r_shift: u5 = @truncate(@ctz(bmp_header.red_mask));
            const g_shift: u5 = @truncate(@ctz(bmp_header.green_mask));
            const b_shift: u5 = @truncate(@ctz(bmp_header.blue_mask));
            const a_shift: u5 = @truncate(@ctz(bmp_header.alpha_mask));

            for (0..out_image.height) |_| {
                const scanline = y * out_image.width;
                var x: u32 = 0;
                for (0..out_image.width) |_| {
                    const value = try reader.readIntLittle(u32);
                    const r = (value & bmp_header.red_mask) >> r_shift;
                    const g = (value & bmp_header.green_mask) >> g_shift;
                    const b = (value & bmp_header.blue_mask) >> b_shift;
                    const a = (value & bmp_header.alpha_mask) >> a_shift;

                    const pixel = a << 24 | b << 16 | g << 8 | r;
                    out_image.pixels[scanline + x] = pixel;
                    x += 1;
                }
                y += @bitCast(increment);
            }
        },
        else => return error.UnsupportedCompressionFormat,
    }

    return out_image;
}
