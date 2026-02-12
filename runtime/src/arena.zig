const Self = @This();
const Utils = @import("utils.zig");
const Allocator = @import("allocator.zig");
const DeadSpan = @import("dead_span.zig");
const Object = @import("object.zig");


start: usize,
size: usize, // usize (instead u16) for large object
// <---------------------------- 0
// managed
neg_offset_to_black_bitset: u16 = 0,
neg_offset_to_gray_bitset: u16 = 0,
// unmanaged
neg_offset_to_frees: u16 = 0,
// ...
neg_offset_to_index_table_into_dead_spans_list: u16 = 0, // []u16
neg_offset_to_dead_spans_list: u16 = 0,
// <---------------------------- start
// ...
// objects
// ...
// <---------------------------- start + size
//
memory_used: usize,


const COUNT_OF_CATEGORYS = 26;


pub fn cmp(a: Self, b: Self) bool {
	return a.start > b.start;
}

pub fn init(self: *Self, size: usize, large: bool, native: bool)
Allocator.AllocatorError!void {
	const bytes = Allocator.calloc(size, u8)
		orelse Allocator.AllocatorError.OOM;

	self.size = size;
	self.start = @intFromPtr(bytes.ptr);
	if (large) return;

	self.neg_offset_to_dead_spans_list = self.size / 8;
	self.neg_offset_to_index_table_into_dead_spans_list = self.neg_offset_to_dead_spans_list + COUNT_OF_CATEGORYS * @sizeOf(u16);
	const next_offset = self.neg_offset_to_index_table_into_dead_spans_list + self.size / 64;
	if (native) {
		self.neg_offset_to_frees = next_offset;
		return;
	}
	self.neg_offset_to_gray_bitset = next_offset;
	self.neg_offset_to_black_bitset = self.neg_offset_to_gray_bitset + self.size / 64;
	const size_of_meta = self.neg_offset_to_black_bitset + self.size / 64;
	self.start += size_of_meta;
	self.size -= size_of_meta;
}

pub fn is_large(self: *Self) bool {
	return self.neg_offset_to_dead_spans_list == 0;
}

pub fn is_native(self: *Self) bool {
	return self.neg_offset_to_frees;
}

fn num_of_highest_set(n: usize) usize {
	return @bitSizeOf(usize) - @clz(n) - 1;
}

fn category_of_object_by_size(size: usize) u16 {
	const num_of_category = Utils.max(num_of_highest_set(size), 3) - 3; // num_of_highest_set([8-15]) = 3
	return num_of_category;
}

fn category_of_span_by_size(size: usize) u16 {
	const num_of_category = Utils.max(num_of_highest_set(size), 5) - 5; // num_of_highest_set([8-63]) = 5
	return num_of_category;
}

fn len_of_index_table(self: *Self) usize {
	return (self.neg_offset_to_index_table_into_dead_spans_list - self.neg_offset_to_dead_spans_list) / 2;
}

fn get_index_table_into_dead_spans_list(self: *Self) usize {
	return self.start - self.neg_offset_to_index_table_into_dead_spans_list;
}

fn len_of_dead_spans_list(self: *Self) usize {
	return self.neg_offset_to_dead_spans_list / 2;
}

fn get_dead_spans_list(self: *Self) usize {
	return self.start - self.neg_offset_to_dead_spans_list;
}

fn get_index_table_array(self: *Self) []u16 {
	return Utils.usize2array_of(
		self.get_index_table_into_dead_spans_list(),
		COUNT_OF_CATEGORYS
	);
}

fn get_dead_spans_list_array(self: *Self) []DeadSpan {
	return Utils.usize2array_of(
		self.get_dead_spans_list(),
		self.len_of_dead_spans_list()
	);
}

pub fn alloc(self: *Self, size: usize) ?usize {
	if (((size << 3) >> 3) != size)
		size = ((size >> 3) + 1) << 3;
	if (size > self.size) return null;
	if (self.is_large()) return self.start;

	const index_table_into_dead_spans_list = Utils.usize2array_of(
		u16,
		self.get_index_table_into_dead_spans_list(),
		self.len_of_index_table()
	);

	const category_of_object = category_of_object_by_size(size);
	const index_of_dead_span = index_table_into_dead_spans_list[category_of_object];
	if (index_of_dead_span == len_of_index_table) return null;

	const dead_spans_list = self.get_dead_spans_list_array();
	const dead_span = &dead_spans_list[index_of_dead_span];
	const size_of_span: u16 = dead_span.get_size(self.start);
	const category_of_span = category_of_span_by_size(size_of_span);
	const new_size_of_span = size_of_span - size;
	const new_category_of_span = category_of_span_by_size(new_size_of_span);
	if (new_category_of_span < category_of_span)
		index_table_into_dead_spans_list[category_of_span] += 1;

	defer dead_span.set_size(self.start, new_category_of_span);
	defer dead_span.shift(size);

	return dead_span.get_size(self.start);
}

fn set_bit(self: *Self, neg_offset: u16, ptr: usize) void {
	const offset = ptr - self.start;
	var bitset = Utils.usize2array_of(u8, self.start - neg_offset, self.size / 64);
	const i = offset / 8;
	const j = offset % 8;

	bitset[i] |= (1 << j);
}

pub fn free(self: *Self, ptr: usize) Allocator.AllocatorError!void {
	if (!self.is_native()) return Allocator.AllocatorError.FreeOnManagedArena;

	self.set_bit(self.neg_offset_to_frees, ptr);
}

fn offset_by_byte_and_bit(byte: usize, bit: usize) u16 {
	return 8 * (8 * byte + bit);
}

fn ptr_by_byte_and_bit(self: *Self, byte: usize, bit: usize) usize {
	return self.start + offset_by_byte_and_bit(byte, bit);
}

fn register_span(self: *Self,
	category: u16,
	size_of_span: u16,
	start_of_span: DeadSpan,
	dead_spans_list: []DeadSpan,
	i: *usize,
	is_last_category: *bool
) void {
	const actual_category = category_of_object_by_size(size_of_span);
	if (category == actual_category) {
		dead_spans_list[i] = DeadSpan.from_ptrs(self.start, start_of_span);
		i.* += 1;
	} else if (category < actual_category) {
		is_last_category.* = false;
	}
}

fn start_of_span_by_last_object(self: *Self, last_object: usize) usize {
	var start_of_span = self.start;
	if (last_object != 0) {
		const addr_of_last_object: **Object = @ptrFromInt(last_object);
		start_of_span = addr_of_last_object.*.size + last_object;
	}
	return start_of_span;
}

fn rebuild(self: *Self) void {
	const dead_spans_list = self.get_dead_spans_list_array();
	var i = 0;
	const table = self.get_index_table_array();
	var offset: u16 = undefined;
	if (self.is_native()) {
		offset = self.neg_offset_to_frees;
	} else {
		offset = self.neg_offset_to_black_bitset;
	}
	const bitset = Utils.usize2array_of(u8, self.start - offset, self.size / 64);
	for (0..COUNT_OF_CATEGORYS) |category| {
		var is_last_category = true;

		table[category] = i;
		var in_span = true;
		var last_object: usize = 0;
		for (bitset, 0..) |byte_of_bitset, num_of_byte| {
			if (byte_of_bitset == 0) {
				in_span = true;
				continue;
			}

			for (0..8) |num_of_bit| {
				if (byte_of_bitset & (1 << num_of_bit)) {
					if (in_span) {
						const start_of_span = self.start_of_span_by_last_object(last_object);
						const end_of_span = self.ptr_by_byte_and_bit(num_of_byte, num_of_bit);
						const size_of_span = end_of_span - start_of_span;
						self.register_span(category,
							size_of_span,
							start_of_span,
							dead_spans_list,
							&i,
							&is_last_category
						);
						in_span = false;
					}
					last_object = self.ptr_by_byte_and_bit(num_of_byte, num_of_bit);
				}
			}
		}
		if (!in_span) {
			const start_of_span = self.start_of_span_by_last_object(last_object);
			const size_of_span = self.start + self.size - self.start_of_span_by_last_object(last_object);
			self.register_span(category,
				size_of_span,
				start_of_span,
				dead_spans_list,
				&i,
				&is_last_category
			);
		}
		if (is_last_category and (category != COUNT_OF_CATEGORYS - 1)) {
			for (category..COUNT_OF_CATEGORYS) |empty_category| {
				table[empty_category] = self.len_of_dead_spans_list();
			}
		}
	}
}
