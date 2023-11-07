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

const Header = struct {
    identifier: [2]u8,
    filesize: u32 align(1),
    reserved: u32 align(1),
    image_offset: u32 align(1),
};

const DibHeader = struct {
    header_size: u32 align(1),
    width: i32 align(1),
    height: i32 align(1),
    n_color_planes: u16 align(1),
    bpp: u16 align(1),
    compression_type: CompressionType align(1),
    image_size: u32 align(1),
    x_pixels_per_meter: i32 align(1),
    y_pixels_per_meter: i32 align(1),
    n_colors: u32 align(1),
    n_important_colors: u32 align(1),
    red_mask: u32 align(1),
    green_mask: u32 align(1),
    blue_mask: u32 align(1),
    alpha_mask: u32 align(1),
    color_space: u32 align(1),
};

fn supportedCompression(compression_type: CompressionType) bool {
    return compression_type == .bitfields or compression_type == .rgb;
}

fn fourCC(comptime a: u8, comptime b: u8, comptime c: u8, comptime d: u8) u32 {
    return (@as(u32, a) << 24) | (@as(u32, b) << 16) | (@as(u32, c) << 8) | @as(u32, d);
}

pub fn load(allocator: mem.Allocator, filename: []const u8, flip_vertically: bool) !Image {
    std.debug.assert(mem.endsWith(u8, filename, ".bmp"));

    const image = try std.fs.cwd().openFile(filename, .{});
    defer image.close();
    const image_data = try image.readToEndAlloc(allocator, std.math.maxInt(usize));

    const bmp_header: *const Header = @alignCast(@ptrCast(image_data.ptr));
    const dib_header: *const DibHeader = @alignCast(@ptrCast(image_data.ptr + @sizeOf(Header)));

    if (!mem.eql(u8, &bmp_header.identifier, &[2]u8{ 'B', 'M' }))
        return error.InvalidBmpFile;

    if (dib_header.bpp != 32 and dib_header.bpp != 24)
        return error.UnsupportedBppFormat;

    if (dib_header.n_colors != 0)
        return error.UnsupportedColorPalette;

    const srgb_ident = comptime fourCC('s', 'R', 'G', 'B');
    const win_ident = comptime fourCC('W', 'i', 'n', ' ');
    const is_srgb = dib_header.color_space == srgb_ident or dib_header.color_space == win_ident;
    if (!is_srgb)
        return error.UnsupportedColorSpace;

    var flipped = dib_header.height < 0;
    const pixel_width = dib_header.bpp / 8;
    const image_size = dib_header.bpp * @divTrunc(dib_header.width, 32) * 4;
    const stride = std.mem.alignForward(u32, @as(u32, @intCast(image_size)), @alignOf(u32));

    const alloc_size = dib_header.width * 4 * dib_header.height;
    var pixels = try allocator.alloc(u32, @as(usize, @intCast(alloc_size)));
    var out_image = Image{
        .allocator = allocator,
        .pixels = pixels,
        .width = @intCast(dib_header.width),
        .height = if (flipped) @intCast(-dib_header.height) else @intCast(dib_header.height),
        .bpp = dib_header.bpp,
    };
    var current_row = image_data.ptr + bmp_header.image_offset;
    if (flip_vertically) flipped = !flipped;
    if (flipped) current_row += stride * (out_image.height - 1);

    switch (dib_header.compression_type) {
        .rgb => {
            for (0..out_image.height) |j| {
                for (0..out_image.width) |i| {
                    const b = current_row[i * pixel_width];
                    const g = current_row[i * pixel_width + 1];
                    const r = current_row[i * pixel_width + 2];
                    const a = 0xFF;
                    const pixel: u32 = (@as(u32, a) << 24) | (@as(u32, b) << 16) | (@as(u32, g) << 8) | @as(u32, r);
                    out_image.pixels[j * out_image.width + i] = pixel;
                }
            }
        },
        .bitfields => {},
        else => return error.UnsupportedCompressionFormat,
    }

    return out_image;
}
