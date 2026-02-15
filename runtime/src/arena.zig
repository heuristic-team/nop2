const Self = @This();
const Utils = @import("utils.zig");
const Allocator = @import("allocator.zig");
const DeadSpan = @import("dead_span.zig");
const Object = @import("object.zig");
const BitsetIterator = @import("bitset_iterator.zig");

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
	// const alloca = std.testing.allocator;
  var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
  const alloca = arena.allocator();
	var s = std.array_list.Managed(u8).init(alloca);
	defer s.deinit();
	try s.appendSlice("lives:\n");
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
      try s.append('|');
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
		try s.appendSlice(try std.fmt.bufPrint(buf[0..], "|{d}:{d}({d})", .{i, ds[i].offset, ds[i].get_size(self.start)}));
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


	self.neg_offset_to_dead_spans_list = roundUpTo64(self.size_by_8());
  // @import("std").debug.print("{}\n", .{self});
  const count_of_categorys_u16: u16 = @intCast(self.count_of_categorys);
	self.neg_offset_to_index_table_into_dead_spans_list = roundUpTo64(
    self.neg_offset_to_dead_spans_list + count_of_categorys_u16 * @sizeOf(u16)
  );
	const next_offset = roundUpTo64(self.neg_offset_to_index_table_into_dead_spans_list + self.size_by_64());
	if (native) {
		self.neg_offset_to_lives = next_offset;
		self.start += next_offset;
		self.size  -= next_offset;
		return;
	}
	self.neg_offset_to_gray_bitset = next_offset;
	self.neg_offset_to_black_bitset = roundUpTo64(self.neg_offset_to_gray_bitset + self.size_by_64());
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
	// @import("std").debug.print("size: {d}\nnum of cat: {d}\nmax cat:{d}\n", .{size, num_of_category, self.count_of_categorys});
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
  @import("std").debug.print("allllllllllllllllllllllllllloca {d}\n", .{not_align_size});
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
	// @import("std").debug.print("cat: {d}\n", .{category_of_object});
	const index_of_dead_span = index_table_into_dead_spans_list[category_of_object];
	if (index_of_dead_span == self.count_of_categorys) return null;

	const dead_spans_list = self.get_dead_spans_list_array();
	const dead_span = &dead_spans_list[index_of_dead_span];
	const size_of_span: u16 = dead_span.get_size(self.start);
	// @import("std").debug.print("size_of_span: {d}\nstart_of_span: {d}\n", .{size_of_span, dead_span.offset});
	const category_of_span = self.category_of_span_by_size(size_of_span);
	const new_size_of_span = size_of_span - size;
  const ptr = dead_span.start(self.start);
  if (new_size_of_span > 7) {
    const new_category_of_span = self.category_of_span_by_size(new_size_of_span);
    if (new_category_of_span < category_of_span)
      index_table_into_dead_spans_list[category_of_span] += 1;

    dead_span.shift(@intCast(size));
    dead_span.set_size(self.start, new_size_of_span);
  } else {
    index_table_into_dead_spans_list[category_of_span] += 1;
  }

  if (self.is_native())
    self.set_bit(self.neg_offset_to_lives, ptr, 1);
	return ptr;
}

fn set_bit(self: *Self, neg_offset: Offset, ptr: usize, bit: u1) void {
	const offset: u16 = @intCast(ptr - self.start);
  // @import("std").debug.print("offset = {d}\n", .{offset});
  const num_of_bit = offset / 8;
	var bitset = Utils.usize2array_of(u8, self.start - neg_offset, self.size_by_64());
	const i = num_of_bit / 8;
	const j: u3 = @intCast(num_of_bit % 8);
  if (bit == 1) {
    bitset[i] |= (U8_1 << j);
  } else {
    bitset[i] &= ~(U8_1 << j);
  }
}

pub fn free(self: *Self, ptr: usize) Allocator.AllocatorError!void {
	if (!self.is_native()) return Allocator.AllocatorError.FreeOnManagedArena;

	self.set_bit(self.neg_offset_to_lives, ptr, 0);
}

fn register_span(self: *Self,
	category: usize,
	size_of_span: u16,
	start_of_span: usize,
	dead_spans_list: []DeadSpan,
	i: *u16,
	is_last_category: *bool
) void {
	// @import("std").debug.print(
 //     \\try to register span on:
 //     \\start of arena= {x}
 //     \\start of span = {x}
 //     \\size of span  = {d}
 //     \\category =      {d}
 //     \\index =         {d}
 //     \\
 // , .{self.start, start_of_span, size_of_span, category, i.*});
	const actual_category = self.category_of_span_by_size(size_of_span);
	if (category == actual_category) {
		// @import("std").debug.print("register!!!!!!!!!!!!!!!\n", .{});
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
		start_of_span = roundUpTo8(addr_of_last_object.*.size) + last_object;
	}
  // @import("std").debug.print("start of span {x}\n", .{start_of_span});
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
    // @import("std").debug.print("start of loop with category={d}: \n{s}", .{category, self.toString() catch unreachable});
		var is_last_category = true;

		table[category] = i;
    var is_first_check = true;
		var last_object: usize = 0;
    var iter = BitsetIterator.from_offset(0);
    byte_cyrcle: while (iter.num_of_byte < bitset.len) {
      // @import("std").debug.print("iter: {d}\n", .{iter.get_offset()});
      // @import("std").debug.print("start of loop with num_of_byte={d}: \n{s}", .{iter.num_of_byte, self.toString() catch unreachable});
      const byte_of_bitset = bitset[iter.num_of_byte];
			// if (byte_of_bitset == 0) {
        // is_first_check = false;
        // iter.num_of_byte += 1;
				// continue;
			// }

      while (iter.num_of_bit < 8) {
        // @import("std").debug.print("inner: {d}\n", .{iter.get_offset()});
				if ((byte_of_bitset & (U8_1 << @intCast(iter.num_of_bit))) != 0) {
          // @import("std").debug.print("find bit on offset {d}\n", .{iter.get_offset()});
          const end_of_span = iter.ptr_by_base(self.start);
          if (!is_first_check) {
            const start_of_span = self.start_of_span_by_last_object(last_object);
            // @import("std").debug.print(
            //     \\start {x}
            //     \\end   {x}
            //     \\last obj {x}
            //     \\
            // , .{start_of_span, end_of_span, last_object});
            const size_of_span: u16 = @intCast(end_of_span - start_of_span);
            self.register_span(category,
              size_of_span,
              start_of_span,
              dead_spans_list,
              &i,
              &is_last_category
            );
          }
          is_first_check = true;
					last_object = end_of_span;

          // @import("std").debug.print("set iter {d}\n", .{self.start_of_span_by_last_object(end_of_span) - self.start});
          iter.set_by_offset(@intCast(self.start_of_span_by_last_object(end_of_span) - self.start));

          // @import("std").debug.print("set offset to {d}\n", .{iter.get_offset()});

          continue :byte_cyrcle;
				}
        is_first_check = false;

        iter.num_of_bit += 1;
			}
      iter.num_of_bit = 0;

      iter.num_of_byte += 1;
		}
		if (!is_first_check) {
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
		  if (last_object == 0) return true;
		}
    // @import("std").debug.print("end of rebuild: \n{s}", .{self.toString() catch unreachable});
	}
	return false;
}

const type64 = Object{
  .size = 64,
  .bitset = &[_]u8{0} ** 8,
};

const type100 = Object{
  .size = 100,
  .bitset = &[_]u8{0} ** 13,
};

const type8 = Object{
  .size = 8,
  .bitset = &[_]u8{0},
};


const eq = @import("test.zig").equ;


fn test_alloc(self: *Self, o: *const Object) !usize {
  const ptr = self.alloc(o.size);
  @import("std").debug.print("{s}", .{try self.toString()});
  try eq(ptr == null, false);
  const addr: **const Object = @ptrFromInt(ptr.?);
  addr.* = o;
  return ptr.?;
}

test "test1" {
	var a = Self{};
	try a.init(1024, false, true);
	// @import("std").debug.print("{s}", .{try a.toString()});

	try eq(a.is_native(), true);
	try eq(a.is_large(), false);

  _= try a.test_alloc(&type8);
  const ptr2 = try a.test_alloc(&type8);
  _= try a.test_alloc(&type8);
  const ptr3 = try a.test_alloc(&type100);
  _= try a.test_alloc(&type8);
  const ptr4 = try a.test_alloc(&type8);
  _= try a.test_alloc(&type8);
  const ptr5 = try a.test_alloc(&type8);
  _= try a.test_alloc(&type8);
  const ptr6 = try a.test_alloc(&type100);
  _ = try a.test_alloc(&type100);
  _ = try a.test_alloc(&type100);
  _= try a.test_alloc(&type8);
  const ptr7 = try a.test_alloc(&type8);
  _= try a.test_alloc(&type8);
  @import("std").debug.print("before free: \n{s}", .{try a.toString()});
  try a.free(ptr2);
  try a.free(ptr3);
  try a.free(ptr4);
  try a.free(ptr5);
  try a.free(ptr6);
  try a.free(ptr7);
  @import("std").debug.print("after free: \n{s}", .{try a.toString()});
  _=a.rebuild();
  @import("std").debug.print("after rebuild:\n{s}", .{try a.toString()});
  // @import("std").debug.print("before free: \n{s}", .{try a.toString()});
  // _= try a.test_alloc(&type8);
  // @import("std").debug.print("after alloca \n", .{});
  // _= try a.test_alloc(&type8);
  // @import("std").debug.print("after alloca \n", .{});
  // _= try a.test_alloc(&type8);
  // @import("std").debug.print("after alloca \n", .{});
  for (0..50) |_| {
    _= try a.test_alloc(&type8);
    // var ptr = try a.test_alloc(&type100);
    // _= try a.test_alloc(&type8);
    // try a.free(ptr);
    // _= try a.test_alloc(&type8);
    // ptr = try a.test_alloc(&type64);
    // _= try a.test_alloc(&type8);
    // try a.free(ptr);
  }
  _=a.rebuild();
  @import("std").debug.print("after rebuild:\n{s}", .{try a.toString()});

}

test "test2" {
  @import("std").debug.print("TEST2", .{});
  var a = Self{};
  try a.init(1024, false, true);

  _= try a.test_alloc(&type8);
  _= try a.test_alloc(&type8);
  var ptr = try a.test_alloc(&type100);
  _= try a.test_alloc(&type8);
  _= try a.test_alloc(&type8);
  try a.free(ptr);
  ptr = try a.test_alloc(&type100);
  _= try a.test_alloc(&type8);
  _= try a.test_alloc(&type8);
  try a.free(ptr);
  ptr = try a.test_alloc(&type100);
  _= try a.test_alloc(&type8);
  _= try a.test_alloc(&type8);
  try a.free(ptr);
  ptr = try a.test_alloc(&type8);
  _= try a.test_alloc(&type8);
  try a.free(ptr);
  ptr = try a.test_alloc(&type8);
  _= try a.test_alloc(&type8);
  try a.free(ptr);
  ptr = try a.test_alloc(&type8);
  _= try a.test_alloc(&type8);
  try a.free(ptr);
  _= try a.test_alloc(&type8);

  _=a.rebuild();
  @import("std").debug.print("after rebuild:\n{s}", .{try a.toString()});
  _= try a.test_alloc(&type64);
}
