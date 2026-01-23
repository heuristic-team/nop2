const Self = @This();

start: usize,
size: u16,
neg_offset_to_gray_bitset: u16 = 0,
neg_offset_to_black_bitset: u16 = 0,
neg_offset_to_index_table_into_dead_spans_list: u16 = 0,
neg_offset_to_dead_spans_list: u16 = 0,

pub fn cmp(a: Self, b: Self) bool {
	@import("std").debug.print("{} > {}?\n", .{a.start, b.start});
	return a.start > b.start;
}