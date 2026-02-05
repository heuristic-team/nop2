const Self = @This();
const Allocator = @import("allocator.zig");

start: usize,
size: usize, // usize (instead u16) for large object
neg_offset_to_black_bitset: u16 = 0,
neg_offset_to_gray_bitset: u16 = 0,
neg_offset_to_index_table_into_dead_spans_list: u16 = 0, // []u16
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

pub fn is_large(self: *Self) bool {
	return self.neg_offset_to_gray_bitset == 0;
}

pub fn is_native(self: *Self) bool {
	return self.neg_offset_to_black_bitset == 0;
}

fn num_of_highest_set(n: usize) usize {
	return @bitSizeOf(usize) - @clz(n) - 1;
}

fn usize2array_of_u16(addr: usize, len: usize) []u16 {
	const ptr: [*]u16 = @ptrFromInt(addr);
	return ptr[0..len];
}

fn index_by_size(size: usize) u16 {
	const num_of_category = num_of_highest_set(size) - 3; // num_of_highest_set([8-15)) = 3
	return num_of_category;
}

pub fn alloc(self: *Self, size: usize) ?usize {
	if (size > self.size) return null;
	if (self.is_large()) return self.start;

	const len_of_index_table = (self.neg_offset_to_index_table_into_dead_spans_list - self.neg_offset_to_dead_spans_list) / 2;

	const index_table_into_dead_spans_list = usize2array_of_u16(
		self.start - self.neg_offset_to_index_table_into_dead_spans_list,
		len_of_index_table);
	const index = index_by_size(size);
	var index_of_dead_span = index_table_into_dead_spans_list[index];

	if (index_of_dead_span == len_of_index_table) return null;

	for (1 + index..) |index_of_real| {
		if (index_of_real) // todo
		if (index_of_dead_span != index_table_into_dead_spans_list[index_of_real]) {

		}
	}
}