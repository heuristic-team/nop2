const Utils = @import("utils.zig");


pub fn runtime_static_array(comptime T: type) type {
	return struct {
		ptr: []T,
		cur: usize,

		const Self = @This();
		pub fn pop(self: *Self) ?T {
			if (self.cur == 0) return null;
			const item = self.ptr[self.cur - 1];
			self.cur -= 1;
			return item;
		}

		pub fn push(self: *Self, value: T) void {
			self.ptr[self.cur] = value;
			self.cur += 1;
		}

		pub fn init(size: usize) ?Self {
			return Self{
				.cur = 0,
				.ptr = Utils.calloc(size, T) orelse return null
			};
		}
	};
}

test "push pop" {
	const equ = @import("test.zig").equ;

	var stack = runtime_static_array(usize).init(3).?;
	stack.push(4);
	stack.push(3);
	stack.push(5);

	try equ(stack.pop(), 5);
	try equ(stack.pop(), 3);
	try equ(stack.pop(), 4);
}

