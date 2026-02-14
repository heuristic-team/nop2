const Self = @This();
const Utils = @import("utils.zig");
const Allocator = @import("allocator.zig");
const DeadSpan = @import("dead_span.zig");
const Object = @import("object.zig");

const Category = u4;
const Offset = u16;


start: usize = 0,
size: usize = 0, // usize (instead u16) for large object
// <---------------------------- 0
// managed
neg_offset_to_black_bitset: Offset = 0,
neg_offset_to_gray_bitset: Offset = 0,
// unmanaged
neg_offset_to_lives: Offset = 0,
// ...
neg_offset_to_index_table_into_dead_spans_list: Offset = 0, // []u16
neg_offset_to_dead_spans_list: Offset = 0,
// <---------------------------- start
// ...
// objects
// ...
// <---------------------------- start + size
//
memory_used: usize = 0,

count_of_categorys: Category = 15,


const U8_1: u8 = 1;


pub fn toString(self: *Self) ![]const u8 {
	const std = @import("std");
	const alloca = std.testing.allocator;
	var s = std.array_list.Managed(u8).init(alloca);
	defer s.deinit();
	try s.appendSlice("lives: ");
	if (self.is_native()) {
		// try s.appendSlice(alloca, "frees: ");
		const f = Utils.usize2array_of(u8, self.start - self.neg_offset_to_lives, self.size_by_64());
		for (f) |value| {
			for (0..8) |num_of_bit| {
				if (value & (@as(u8, 1) << @intCast(num_of_bit)) == 0) {
					try s.append('0');
				} else {
					try s.append('1');
				}
			}
		}
		try s.append('\n');
	}
	const table = self.get_index_table_array();
	for (0..self.count_of_categorys) |i| {
		var buf: [64]u8 = undefined;
		try s.appendSlice(try std.fmt.bufPrint(buf[0..], "{d:>12}", .{i}));
	}

	try s.append('\n');

	for (0..self.count_of_categorys) |i| {
		var buf: [64]u8 = undefined;
		var buf2: [64]u8 = undefined;
		const bounds = bounds_of_span_by_category(@intCast(i));
		try s.appendSlice(try std.fmt.bufPrint(buf[0..], "{s:>12}", .{
			try std.fmt.bufPrint(buf2[0..], "[{d},{d}]", bounds)
		}));
	}

	try s.append('\n');

	for (0..self.count_of_categorys) |i| {
		var buf: [64]u8 = undefined;
		try s.appendSlice(try std.fmt.bufPrint(buf[0..], "{d:>12}", .{table[i]}));
	}

	try	s.append('\n');
	try s.appendSlice("\ndead_spans: ");

	const ds = self.get_dead_spans_list_array();
	for (0..ds.len) |i| {
		var buf: [64]u8 = undefined;
		try s.appendSlice(try std.fmt.bufPrint(buf[0..], "|{d}({d})", .{ds[i].offset, ds[i].get_size(self.start)}));
	}

	try s.append('\n');

	return s.toOwnedSlice();
}

pub fn cmp(a: Self, b: Self) bool {
	return a.start > b.start;
}

fn size_by_64(self: *Self) Offset {
  return @intCast(roundUpTo64(self.size) / 64);
}

fn size_by_8(self: *Self) Offset {
	return @intCast(roundUpTo8(self.size) / 8);
}

fn roundUpTo8(x: anytype) @TypeOf(x) {
	return (x + 7) & ~@as(@TypeOf(x), 7);
}

fn roundUpTo64(x: anytype) @TypeOf(x) {
  return (x + 63) & ~@as(@TypeOf(x), 63);
}

pub fn init(self: *Self, size: usize, large: bool, native: bool)
Allocator.AllocatorError!void {
	const bytes = Utils.calloc(size, u8)
		orelse Allocator.AllocatorError.OOM;

	defer @import("std").debug.print("start = {x}\n", .{self.start});

	self.size = size;
	self.start = @intFromPtr((try bytes).ptr);
	if (large) return;
	self.count_of_categorys = self.category_of_object_by_size(self.size);
	defer _=self.rebuild();

	self.neg_offset_to_dead_spans_list = roundUpTo8(self.size_by_8());
	self.neg_offset_to_index_table_into_dead_spans_list = roundUpTo8(self.neg_offset_to_dead_spans_list + self.count_of_categorys * @sizeOf(u16));
	const next_offset = roundUpTo8(self.neg_offset_to_index_table_into_dead_spans_list + self.size_by_64());
	if (native) {
		self.neg_offset_to_lives = next_offset;
		self.start += next_offset;
		self.size  -= next_offset;
		return;
	}
	self.neg_offset_to_gray_bitset = next_offset;
	self.neg_offset_to_black_bitset = roundUpTo8(self.neg_offset_to_gray_bitset + self.size_by_64());
	self.start += self.neg_offset_to_black_bitset;
	self.size  -= self.neg_offset_to_black_bitset;
}

pub fn is_large(self: *Self) bool {
	return self.neg_offset_to_dead_spans_list == 0;
}

pub fn is_native(self: *Self) bool {
	return self.neg_offset_to_lives > 0;
}

fn num_of_highest_set(n: usize) usize {
	return @bitSizeOf(usize) - @clz(n) - 1;
}

fn bounds_of_span_by_category(category: Category) struct { u16, u16 } {
	if (category == 0) return .{8, 63};
	return .{@as(u16, 32) << category, (@as(u16, 64) << category) - 1};
}

fn category_of_object_by_size(self: *Self, size: usize) Category {
	const num_of_category = Utils.max(usize, num_of_highest_set(size), 3) - 3; // num_of_highest_set([8-15]) = 3
	@import("std").debug.print("size: {d}\nnum of cat: {d}\nmax cat:{d}\n", .{size, num_of_category, self.count_of_categorys});
	if (num_of_category >= self.count_of_categorys) unreachable;
	return @intCast(num_of_category);
}

fn category_of_span_by_size(self: *Self, size: usize) Category {
	const num_of_category = Utils.max(usize, num_of_highest_set(size), 5) - 5; // num_of_highest_set([8-63]) = 5
	if (num_of_category >= self.count_of_categorys) unreachable;
	return @intCast(num_of_category);
}

fn get_index_table_into_dead_spans_list(self: *Self) usize {
	return self.start - self.neg_offset_to_index_table_into_dead_spans_list;
}

fn len_of_dead_spans_list(self: *Self) usize {
	return self.neg_offset_to_dead_spans_list / @sizeOf(@TypeOf(self.neg_offset_to_dead_spans_list));
}

fn get_dead_spans_list(self: *Self) usize {
	return self.start - self.neg_offset_to_dead_spans_list;
}

fn get_index_table_array(self: *Self) []u16 {
	// @import("std").debug.print("addr: {d}\n", .{self.get_index_table_into_dead_spans_list()});
	return Utils.usize2array_of(
		u16,
		self.get_index_table_into_dead_spans_list(),
		self.count_of_categorys
	);
}

fn get_dead_spans_list_array(self: *Self) []DeadSpan {
	return Utils.usize2array_of(
		DeadSpan,
		self.get_dead_spans_list(),
		self.len_of_dead_spans_list()
	);
}

pub fn alloc(self: *Self, not_align_size: usize) ?usize {
  @import("std").debug.print("allllllllllllllllllllllllllloca\n", .{});
	const size: u16 = @intCast(roundUpTo8(not_align_size));
	@import("std").debug.print("size: {d}\n", .{size});
	if (size > self.size) return null;
	if (self.is_large()) return self.start;

	const index_table_into_dead_spans_list = Utils.usize2array_of(
		u16,
		self.get_index_table_into_dead_spans_list(),
		self.count_of_categorys
	);

	const category_of_object = self.category_of_object_by_size(size);
	@import("std").debug.print("cat: {d}\n", .{category_of_object});
	const index_of_dead_span = index_table_into_dead_spans_list[category_of_object];
	if (index_of_dead_span == self.count_of_categorys) return null;

	const dead_spans_list = self.get_dead_spans_list_array();
	const dead_span = &dead_spans_list[index_of_dead_span];
	const size_of_span: u16 = dead_span.get_size(self.start);
	@import("std").debug.print("size_of_span: {d}\nstart_of_span: {d}\n", .{size_of_span, dead_span.offset});
	const category_of_span = self.category_of_span_by_size(size_of_span);
	const new_size_of_span = size_of_span - size;
	const new_category_of_span = self.category_of_span_by_size(new_size_of_span);
	if (new_category_of_span < category_of_span)
		index_table_into_dead_spans_list[category_of_span] += 1;

	defer dead_span.set_size(self.start, new_size_of_span);
	defer dead_span.shift(@intCast(size));

  const ptr = dead_span.start(self.start);
  self.set_bit(self.neg_offset_to_lives, ptr, 1);
	return ptr;
}

fn set_bit(self: *Self, neg_offset: Offset, ptr: usize, bit: u1) void {
	const offset: u16 = @intCast(ptr - self.start);
  const num_of_bit = offset / 8;
	var bitset = Utils.usize2array_of(u8, self.start - neg_offset, self.size_by_64());
	const i = num_of_bit / 8;
	const j: u3 = @intCast(num_of_bit % 8);
  bitset[i] |= (@as(u8, bit) << j);
}

pub fn free(self: *Self, ptr: usize) Allocator.AllocatorError!void {
	if (!self.is_native()) return Allocator.AllocatorError.FreeOnManagedArena;

	self.set_bit(self.neg_offset_to_lives, ptr, 0);
}

fn offset_by_byte_and_bit(byte: usize, bit: usize) u16 {
	return @intCast(8 * (8 * byte + bit));
}

fn ptr_by_byte_and_bit(self: *Self, byte: usize, bit: usize) usize {
	return self.start + offset_by_byte_and_bit(byte, bit);
}

fn register_span(self: *Self,
	category: usize,
	size_of_span: u16,
	start_of_span: usize,
	dead_spans_list: []DeadSpan,
	i: *u16,
	is_last_category: *bool
) void {
	@import("std").debug.print(
     \\try to register span on:
     \\start of span = {x}
     \\size of span  = {d}
     \\category =      {d}
     \\index =         {d}
     \\
 , .{start_of_span, size_of_span, category, i.*});
	const actual_category = self.category_of_span_by_size(size_of_span);
	if (category == actual_category) {
		@import("std").debug.print("register!!!!!!!!!!!!!!!\n", .{});
		dead_spans_list[i.*] = DeadSpan.from_ptrs(self.start, start_of_span);
    dead_spans_list[i.*].set_size(self.start, size_of_span);
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

/// return true if arena is empty
fn rebuild(self: *Self) bool {
	const dead_spans_list = self.get_dead_spans_list_array();
	var i: u16 = 0;
	const table = self.get_index_table_array();
	var offset: Offset = undefined;
	if (self.is_native()) {
		offset = self.neg_offset_to_lives;
	} else {
		offset = self.neg_offset_to_black_bitset;
	}
	const bitset = Utils.usize2array_of(u8, self.start - offset, self.size / 64);
  // @import("std").debug.print("{s}", .{self.toString() catch unreachable});
	for (0..self.count_of_categorys) |category| {
		var is_last_category = true;

		table[category] = i;
		var in_span = true;
		var last_object: usize = 0;
		for (bitset, 0..) |byte_of_bitset, num_of_byte| {
			if (byte_of_bitset == 0) {
				continue;
			}

			for (0..8) |num_of_bit| {
				if ((byte_of_bitset & (U8_1 << @intCast(num_of_bit))) != 0) {
					if (in_span) {
						const start_of_span = self.start_of_span_by_last_object(last_object);
						const end_of_span = self.ptr_by_byte_and_bit(num_of_byte, num_of_bit);
						const size_of_span: u16 = @intCast(end_of_span - start_of_span);
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
		if (in_span) {
			const start_of_span = self.start_of_span_by_last_object(last_object);
			const size_of_span: u16 = @intCast(self.start + self.size - self.start_of_span_by_last_object(last_object));
			self.register_span(category,
				size_of_span,
				start_of_span,
				dead_spans_list,
				&i,
				&is_last_category
			);
		}
		if (is_last_category and (category != self.count_of_categorys - 1)) {
			for (category + 1..self.count_of_categorys) |empty_category| {
				table[empty_category] = @intCast(self.len_of_dead_spans_list());
			}
		  if (in_span and (last_object == 0)) return true;
		}
    @import("std").debug.print("end of rebuild: \n{s}", .{self.toString() catch unreachable});
	}
	return false;
}


test "test1" {
	var a = Self{};
	try a.init(512, false, true);
	// @import("std").debug.print("{s}", .{try a.toString()});

	const eq = @import("test.zig").equ;

	try eq(a.is_native(), true);
	try eq(a.is_large(), false);
	@import("std").debug.print("{s}", .{try a.toString()});
	const ptr1 = a.alloc(64);
  try eq(ptr1 == null, false);
  @import("std").debug.print("{s}", .{try a.toString()});
  const ptr2 = a.alloc(16);
  try eq(ptr2 == null, false);
  @import("std").debug.print("[{x}] {s}", .{ptr2.?, try a.toString()});
  const ptr3 = a.alloc(20);
  try eq(ptr3 == null, false);
  @import("std").debug.print("{s}", .{try a.toString()});
  try a.free(ptr2.?);
  @import("std").debug.print("{s}", .{try a.toString()});
  _=a.rebuild();
  @import("std").debug.print("{s}", .{try a.toString()});
}
