const Self = @This();
const Config = @import("config.zig");

const AllocatorError = error{InvalidConfig};

pub fn alloc(self: *Self, size: usize) ?[*]u8 {

}

pub fn init(cfg: Config) AllocatorError!*Self {
	if (cfg.log_arena_size < 8) return AllocatorError.InvalidConfig;
	if (cfg.log_arena_size > 26) return AllocatorError.InvalidConfig;
	if ((1 << cfg.log_arena_size) < cfg.max_size_of_object_on_arena)
		return AllocatorError.InvalidConfig;
}