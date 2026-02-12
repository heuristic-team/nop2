const c = @cImport({
	@cInclude("stdlib.h");
});

pub fn min(comptime T: type, a: T, b: T) T {
	if (a > b) return b;
	return a;
}

pub fn max(comptime T: type, a: T, b: T) T {
	if (a < b) return b;
	return a;
}

pub fn calloc(count: usize, T: type) ?[]T {
	const raw: [*]T = @ptrCast(@alignCast(c.malloc(@sizeOf(T) * count) orelse return null));
	return raw[0..count];
}

pub fn usize2array_of(comptime T: type, addr: usize, len: usize) []T {
	const ptr: [*]T = @ptrFromInt(addr);
	return ptr[0..len];
}
