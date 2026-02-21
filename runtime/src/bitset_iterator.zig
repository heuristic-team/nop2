const Self = @This();


const Offset = u16;


num_of_byte: u14 = 0,
num_of_bit:  u4  = 0,


pub fn from_offset(offset: Offset) Self {
  return Self{
    .num_of_byte = @intCast(offset >> 6),
    .num_of_bit = @intCast((offset >> 3) & 7)
  };
}

pub fn get_offset(self: *Self) Offset {
  return 8 * (8 * self.num_of_byte + self.num_of_bit);
}

pub fn ptr_by_base(self: *Self, base: usize) usize {
  return base + self.get_offset();
}

pub fn set_by_offset(self: *Self, offset: Offset) void {
  const new_self = from_offset(offset);
  // @import("std").debug.print("{}\n", .{new_self});
  self.num_of_bit = new_self.num_of_bit;
  self.num_of_byte = new_self.num_of_byte;
}