const Self = @This();
const TypeSize = u16;

// u are not ready to talk about this
offset: u16,

pub fn from_ptrs(ptr: usize, addr_of_dead_span: usize) Self {
	return Self{.offset = (addr_of_dead_span - ptr) >> 3};
}

pub fn start(self: Self, ptr: usize) usize {
	return ptr + (self.offset << 3);
}

fn ptr_of_size(self: Self, ptr: usize) *TypeSize {
	return @as(*TypeSize, @ptrFromInt(ptr + (self.offset << 3)));
}

pub fn get_size(self: Self, ptr: usize) TypeSize {
	return self.ptr_of_size(ptr).*;
}

pub fn set_size(self: Self, ptr: usize, size: usize) void {
	self.ptr_of_size(ptr).* = size;
}

pub fn shift(self: *Self, size: usize) void {
	self.offset += (size >> 3);
}