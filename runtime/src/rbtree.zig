pub fn rbtree(comptime T: type) type {
	return struct {

		const Self = @This();
		left: ?*Self = null,
		right: ?*Self = null,
		papa: ?*Self = null,
		red: bool = true,
		value: T,
		count: isize = 1,

		const comparator = fn (a: T, b: T) bool;
		pub fn toString(
			self: *const Self,
			allocator: @import("std").mem.Allocator,
			toStringFn: fn(T, @import("std").mem.Allocator) anyerror![]const u8
		) ![]const u8 {
			var buffer = @import("std").ArrayList(u8){};
			defer buffer.deinit(allocator);

			const writer = buffer.writer(allocator);
			try self.toStringRec(writer, "", true, allocator, toStringFn);

			return buffer.toOwnedSlice(allocator);
		}

		fn toStringRec(
			self: *const Self,
			writer: anytype,
			prefix: []const u8,
			is_left: bool,
			allocator: @import("std").mem.Allocator,
			toStringFn: fn(T, @import("std").mem.Allocator) anyerror![]const u8
		) !void {
            if (self.right) |right| {
				const new_prefix = if (is_left)
					try @import("std").fmt.allocPrint(allocator, "{s}│   ", .{prefix})
				else
					try @import("std").fmt.allocPrint(allocator, "{s}    ", .{prefix});
				defer allocator.free(new_prefix);
				try right.toStringRec(writer, new_prefix, false, allocator, toStringFn);
			}

			try writer.print("{s}", .{prefix});
			const branch = if (is_left) "└── " else "┌── ";
			try writer.print("{s}", .{branch});

			const value_str = try toStringFn(self.value, allocator);
			defer allocator.free(value_str);

			try writer.print("{s} ", .{value_str});

			try writer.print("[{s} count={d}]", .{
				if (self.red) "R" else "B",
				self.count,
			});

            if (self.papa) |papa| {
				const papa_str = try toStringFn(papa.value, allocator);
				defer allocator.free(papa_str);
				try writer.print(" (papa: {s})", .{papa_str});
			}

			try writer.print("\n", .{});

            if (self.left) |left| {
				const new_prefix = if (is_left)
					try @import("std").fmt.allocPrint(allocator, "{s}    ", .{prefix})
				else
					try @import("std").fmt.allocPrint(allocator, "{s}│   ", .{prefix});
				defer allocator.free(new_prefix);
				try left.toStringRec(writer, new_prefix, true, allocator, toStringFn);
			}
		}

		fn swap_papa(t: *Self) void {
			swap_vn(t, t.papa.?);
			const temp_red = t.papa.?.red;
			t.papa.?.red = t.red;
			t.red = temp_red;
		}

		fn small_left(t: *Self) void {
			t.papa.?.right = t.right;
			if (t.right) |right|{
				right.papa = t.papa;
			}

			if (t.papa.?.right) |right| {
				t.count -= right.count;
			}

			t.right = t.left;

			t.left = t.papa.?.left;
			if (t.left) |left| {
				left.papa = t;
				t.count += left.count;
			}

			t.papa.?.left = t;
			swap_papa(t);
		}

		fn small_right(t: *Self) void {
			t.papa.?.left = t.left;
			if (t.left) |left| {
				left.papa = t.papa;
			}
			if (t.papa.?.left) |left| {
				t.count -= left.count;
			}

			t.left = t.right;

			t.right = t.papa.?.right;
			if (t.right) |right| {
				right.papa = t;
				t.count += right.count;
			}

			t.papa.?.right = t;
			swap_papa(t);
		}

		fn uncle(tree: *Self) ?*Self {
			if (tree.papa.?.papa == null) {
				return null;
			}
			if (tree.papa.?.papa.?.left == tree.papa) {
				return tree.papa.?.papa.?.right;
			} else {
				return tree.papa.?.papa.?.left;
			}
		}

		fn lower_bound(self: *Self, value_comparator: comparator, value: T) ?T {
			if (value_comparator(self.value, value)) {
				if (self.left) |left| {
					return left.lower_bound(value_comparator, value);
				}
				return null;
			}
			var cur = self;
			while (cur.right != null and value_comparator(value, cur.right.?.value)) {
				cur = cur.right.?;
			}

			if (cur.right) |right| {
				if (right.lower_bound(value_comparator, value))
				|lb_from_right| {
					if (value_comparator(lb_from_right, cur.value)) {
						return lb_from_right;
					}
				}
			}
			return cur.value;
		}

		fn insert_0(value_comparator: comparator, t: *Self, tree: *Self) void {
			if (value_comparator(t.value, tree.value)) {
				if (t.left) |left| {
					insert_0(value_comparator, left, tree);
				} else {
					tree.papa = t;
					tree.papa.?.left = tree;
					fix_count(tree);
					insert_case(tree);
				}
			} else {
				if (t.right) |right| {
					insert_0(value_comparator, right, tree);
				} else {
					tree.papa = t;
					tree.papa.?.right = tree;
					fix_count(tree);
					insert_case(tree);
				}
			}
		}

		fn insert_case(tree: *Self) void {
			if (tree.papa == null) {
				tree.red = false;
			} else {
				insert_case2(tree);
			}
		}

		fn insert_case2(tree: *Self) void {
			if (tree.papa.?.red) {
				insert_case3(tree);
			}
		}

		fn insert_case3(tree: *Self) void {
			const uncl = uncle(tree);
			if (uncl) |u| {
				if (u.red) {
					tree.papa.?.papa.?.red = true;
					tree.papa.?.red = false;
					u.red = false;
					insert_case(tree.papa.?.papa.?);
					return;
				}
			}
			insert_case4(tree);
		}

		fn insert_case4(tree: *Self) void {
			if (tree.papa.?.papa == null) {
				tree.papa.?.red = false;
			} else {
				if (tree == tree.papa.?.right and tree.papa == tree.papa.?.papa.?.left) {
					small_left(tree);
				} else if (tree == tree.papa.?.left and tree.papa == tree.papa.?.papa.?.right) {
					small_right(tree);
				}
				insert_case5(tree);
			}
		}

		fn insert_case5(tree: *Self) void {
			tree.papa.?.red = false;
			tree.papa.?.papa.?.red = true;
			if (tree == tree.papa.?.left and tree.papa == tree.papa.?.papa.?.left) {
				small_right(tree.papa.?);
			} else {
				small_left(tree.papa.?);
			}
		}

		fn minright(tree: *Self) ?*Self {
			if (tree == null) {
				return null;
			}

			if (tree.left == null) {
				return tree;
			} else {
				return minright(tree.left);
			}
		}

		fn maxleft(tree: *Self) ?*Self {
			if (tree.right == null) {
				return tree;
			} else {
				return minright(tree.right);
			}
		}

		fn fix_count(tree: ?*Self) void {
			if (tree) |t| {
			t.count = 1;
				if (t.left) |left| {
					t.count += left.count;
				}
				if (t.right) |right| {
					t.count += right.count;
				}
				fix_count(t.papa);
			}
		}

		fn cutblackRight(maybe_a: ?*Self) void {
			if (maybe_a) |a| {
				fix_count(a);
				var b = a.left.?;
				if (a.red) {
					if (b.count > 1 and (b.right != null and
						b.right.?.red || b.left != null and b.left.?.red)) {
						if (b.right != null and b.right.?.red) {
							a.red = false;
							small_left(b.right);
							small_right(b);
						} else if (b.left != null and b.left.?.red) {
							small_right(b);
							a.red = true;
							a.left.?.red = false;
							a.right.?.red = false;
						}
					} else {
						b.red = true;
						a.red = false;
					}
				} else {
					if (b.red) {
						var c = b.right.?;
						if (c.count > 1) {
							if (c.right != null and c.right.?.red) {
								c.right.red = false;
								small_left(c.right);
								small_left(c);
							} else if (c.left != null and c.left.?.red) {
								c.left.?.red = false;
								small_left(c);
							} else {
								c.red = false;
								c.red = true;
							}
							small_right(b);
						} else {
							b.red = false;
							c.red = true;
							small_right(b);
						}
					} else {
						if (b.right != null and b.right.red) {
							b.right.red = false;
							small_left(b.right);
							small_right(b);
						} else if (b.left != null and b.left.red) {
							b.left.red = false;
							small_right(b);
						} else {
							b.red = true;
							cutblack(a, 'n');
						}
					}
				}
			}
		}

		fn cutblackLeft(maybe_a: ?*Self) void {
			if (maybe_a) |a| {
				fix_count(a);
				var b = a.right.?;
				if (a.red) {
					if (b.count > 1 and (b.right != null and
						b.right.?.red || b.left != null and b.left.?.red)) {
						if (b.left != null and b.left.red) {
							a.red = false;
							small_right(b.left);
							small_left(b);
						} else if (b.right != null and b.right.red) {
							small_left(b);
							a.red = true;
							a.right.red = false;
							a.left.red = false;
							}
					} else {
						b.red = true;
						a.red = false;
						}
				} else {
					if (b.red) {
						var c = b.left.?;
						if (c.count > 1) {
							if (c.left != null and c.left.?.red) {
								c.left.?.red = false;
								small_right(c.left);
								small_right(c);
							} else if (c.right != null and c.right.?.red) {
								c.right.?.red = false;
								small_right(c);
							} else {
								c.red = false;
								c.red = true;
							}
							small_left(b);
						} else {
							b.red = false;
							c.red = true;
							small_left(b);
						}
					} else {
						if (b.left != null and b.left.?.red) {
							b.left.?.red = false;
							small_right(b.left);
							small_left(b);
						} else if (b.right != null and b.right.?.red) {
							b.right.?.red = false;
							small_left(b);
						} else {
							b.red = true;
							cutblack(a, 'n');
						}
					}
				}
			}
		}

		fn cutblack(tree: *Self, rotate: u8) void {
			if (rotate == 'r') {
				cutblackRight(tree);
			} else if (rotate == 'l') {
				cutblackLeft(tree);
			} else {
				if (tree.papa) |papa| {
					if (papa.right == tree) {
						cutblackRight(papa);
					} else {
						cutblackLeft(papa);
					}
				}
			}
		}

		fn swap_vn(t1: *Self, t2: *Self) void {
			const temp = t1.value;
			t1.value = t2.value;
			t2.value = temp;
		}

		fn cut_one(tree: *Self) void {
			const papa = tree.papa.?;
			if (papa.left == tree) {
				tree.papa.?.left = null;
			} else {
				tree.papa.?.right = null;
			}
			tree.papa.?.count -= 1;
			tree.papa = null;
			fix_count(papa);
		}

		fn delete(tree: *Self) bool {
			if (tree.count == 1) {
				if (tree.red) {
					cut_one(tree);
				} else {
					if (tree.papa == null) {
						return true;
					} else {
						if (tree.papa.right == tree) {
							tree.papa.right = null;
							cutblack(tree.papa, 'r');
						} else {
							tree.papa.left = null;
							cutblack(tree.papa, 'l');
						}
					}
				}
			} else if (tree.count == 2) {
				if (tree.right == null) {
					swap_papa(tree.left);
					tree.left.?.papa = null;
					tree.left = null;
				} else {
					swap_papa(tree.right);
					tree.right.?.papa = null;
					tree.right = null;
				}
				tree.red = false;
				tree.count -= 1;
				fix_count(tree.papa);
			} else {
				var swap = minright(tree.right);
				if (swap == null) {
					swap = maxleft(tree.left);
				}
				swap_vn(tree, swap);
				delete(swap);
			}
			return false;
		}
	};
}

test "test with Arena" {
	const c = @cImport({
		@cInclude("stdlib.h");
	});
	const equ = @import("test.zig").equ;
	const Arena = @import("arena.zig");
	const rbt = rbtree(Arena);
	var root = rbt{.value = Arena{.start = 10, .size = 5}};

	const count_of_arenas_for_test = 1000;
	const raw_trees = c.malloc(@sizeOf(rbt) * count_of_arenas_for_test).?;
	var typed_ptr: [*]rbt = @ptrCast(@alignCast(raw_trees));
	var trees = typed_ptr[0..count_of_arenas_for_test];
	for (trees, 0..) |_, i| {
		trees[i] = rbt{.value = Arena{
			.start = 20 + i * 10,
			.size = 5
		}};
		rbt.insert_0(Arena.cmp, &root, &trees[i]);
	}

	for (0..count_of_arenas_for_test / 2) | i| {
		const lower_them = Arena{
			.size = 0,
			.start = 12 + i * 10,
		};
		try equ(root.lower_bound(
			Arena.cmp, lower_them).?.start,
			lower_them.start - 2);
	}
}