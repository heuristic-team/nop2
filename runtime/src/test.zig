pub fn equ(a: anytype, b: @TypeOf(a)) !void {
	@import("std").debug.print("TEST {} =?= {}\n", .{a, b});
	if (a != b) return error.TestFailed;
}