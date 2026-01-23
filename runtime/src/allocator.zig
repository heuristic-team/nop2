const Config = @import("config.zig");
const Arena = @import("arena.zig");
const c = @cImport({
	@cInclude("stdlib.h");
});

const Self = @This();
const AllocatorError = error{InvalidConfig, OOMInInit};
const IndexOfArena = u32;

arena_size: usize,
capacity_of_heap: usize,
arenas: []Arena,

archive_of_arenas: []IndexOfArena,
active_arenas: []IndexOfArena,
current_arena: IndexOfArena,

pub fn alloc(self: *Self, size: usize) ?[*]u8 {

}

pub fn init(cfg: Config) AllocatorError!*Self {
	if (cfg.log_arena_size > cfg.log_capacity_of_heap)
		return AllocatorError.InvalidConfig;
	if (cfg.log_arena_size < 8) return AllocatorError.InvalidConfig;
	if (cfg.log_arena_size > 26) return AllocatorError.InvalidConfig;
	if ((1 << cfg.log_arena_size) < cfg.max_size_of_object_on_arena)
		return AllocatorError.InvalidConfig;

	const count_of_arenas = 1 << (cfg.log_capacity_of_heap - cfg.log_arena_size);
	var this = Self{};
	this.arena_size = 1 << cfg.log_arena_size;
	this.capacity_of_heap = 1 << cfg.log_capacity_of_heap;

	var raw_stack_of_arenas = c.malloc(@sizeOf(Arena) * count_of_arenas)
		orelse return AllocatorError.OOMInInit;
	this.arenas = raw_stack_of_arenas[0..count_of_arenas];

	var raw_archive_of_arenas = c.malloc(@sizeOf(IndexOfArena) * count_of_arenas)
		orelse return AllocatorError.OOMInInit;
	this.archive_of_arenas = raw_archive_of_arenas[0..count_of_arenas];

	var raw_active_of_arenas = c.malloc(@sizeOf(IndexOfArena) * count_of_arenas)
		orelse return AllocatorError.OOMInInit;
	this.active_arenas = raw_active_of_arenas[0..count_of_arenas];

	
}