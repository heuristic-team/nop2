const Self = @This();
const Allocator = @import("allocator.zig");

start: usize,
size: usize, // usize (instead u16) for large object
neg_offset_to_black_bitset: u16 = 0,
neg_offset_to_gray_bitset: u16 = 0,
neg_offset_to_index_table_into_dead_spans_list: u16 = 0,
neg_offset_to_dead_spans_list: u16 = 0,

pub fn cmp(a: Self, b: Self) bool {
	@import("std").debug.print("{} > {}?\n", .{a.start, b.start});
	return a.start > b.start;
}

pub fn init(self: *Self, size: usize, large: bool, native: bool)
Allocator.AllocatorError!void {
	const bytes = @import("allocator.zig").calloc(size, u8)
		orelse Allocator.AllocatorError.OOM;

	self.size = size;
	self.start = @intFromPtr(bytes.ptr);
	if (large) return;

	self.neg_offset_to_dead_spans_list = self.size / 8;
	self.neg_offset_to_index_table_into_dead_spans_list = self.neg_offset_to_dead_spans_list + 32;
	self.neg_offset_to_gray_bitset = self.neg_offset_to_index_table_into_dead_spans_list + self.size / 64;
	if (native) return;
	self.neg_offset_to_black_bitset = self.neg_offset_to_gray_bitset + self.size / 64;
}