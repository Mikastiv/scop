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
    header_size: u32 align(1),
    width: i32 align(1),
    height: i32 align(1),
    n_color_planes: u16 align(1),
    bpp: u16 align(1),
    compression_type: CompressionType align(1),
    image_size: u32 align(1),
    x_pixels_per_meter: u32 align(1),
    y_pixels_per_meter: u32 align(1),
    n_colors: u32 align(1),
    n_important_colors: u32 align(1),
    red_mask: u32 align(1),
    green_mask: u32 align(1),
    blue_mask: u32 align(1),
    alpha_mask: u32 align(1),
    color_space: ColorSpace align(1),
};

pub fn load(allocator: mem.Allocator, filename: []const u8, flip_vertically: bool) !Image {
    std.debug.assert(mem.endsWith(u8, filename, ".bmp"));

    const image = try std.fs.cwd().openFile(filename, .{});
    defer image.close();

    const image_data = try image.readToEndAlloc(allocator, std.math.maxInt(usize));

    const file_header: *const FileHeader = @alignCast(@ptrCast(image_data.ptr));
    const bmp_header: *const BmpHeader = @alignCast(@ptrCast(image_data.ptr + @sizeOf(FileHeader)));

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
    const image_width: usize = @intCast(bmp_header.width);
    const image_height: usize = if (flipped) @intCast(-bmp_header.height) else @intCast(bmp_header.height);

    const pixel_byte_width = std.mem.alignForward(usize, bmp_header.bpp / 8, 4);
    const row_bit_width: usize = @intCast(bmp_header.bpp * bmp_header.width);
    const stride: usize = std.mem.alignForward(usize, row_bit_width / 32 * 4, 4);
    var current_row = image_data.ptr + file_header.image_offset;

    const alloc_size = image_width * 4 * image_height;
    var pixels = try allocator.alloc(u32, alloc_size);
    var out_image = Image{
        .allocator = allocator,
        .pixels = pixels,
        .width = @intCast(image_width),
        .height = @intCast(image_height),
        .bpp = bmp_header.bpp,
    };

    if (flip_vertically) flipped = !flipped;
    if (flipped) current_row += stride * (image_height - 1);
    const stride_int: isize = @intCast(stride);
    const increment: usize = if (flipped) @as(usize, @bitCast(-stride_int)) else @as(usize, @intCast(stride_int));

    switch (bmp_header.compression_type) {
        .rgb => {
            for (0..image_height) |j| {
                for (0..image_width) |i| {
                    const b = current_row[i * pixel_byte_width];
                    const g = current_row[i * pixel_byte_width + 1];
                    const r = current_row[i * pixel_byte_width + 2];
                    const a = 0xFF;
                    const pixel: u32 = (@as(u32, a) << 24) | (@as(u32, b) << 16) | (@as(u32, g) << 8) | @as(u32, r);
                    out_image.pixels[j * image_width + i] = pixel;
                }
                current_row += increment;
            }
        },
        .bitfields => {
            const r_shift: u5 = @truncate(@ctz(bmp_header.red_mask));
            const g_shift: u5 = @truncate(@ctz(bmp_header.green_mask));
            const b_shift: u5 = @truncate(@ctz(bmp_header.blue_mask));
            const a_shift: u5 = @truncate(@ctz(bmp_header.alpha_mask));

            for (0..image_height) |j| {
                for (0..image_width) |i| {
                    const offset = i * pixel_byte_width;
                    const ptr: *[4]u8 = @ptrCast(&current_row[offset]);
                    const value = std.mem.bytesToValue(u32, ptr);
                    const r = (value & bmp_header.red_mask) >> r_shift;
                    const g = (value & bmp_header.green_mask) >> g_shift;
                    const b = (value & bmp_header.blue_mask) >> b_shift;
                    const a = (value & bmp_header.alpha_mask) >> a_shift;

                    const pixel = a << 24 | b << 16 | g << 8 | r;
                    out_image.pixels[j * image_width + i] = pixel;
                }
                current_row += increment;
            }
        },
        else => return error.UnsupportedCompressionFormat,
    }

    return out_image;
}
