const Config = @import("config.zig");
const Arena = @import("arena.zig");
const RBTree = @import("rbtree.zig").rbtree(Arena);
const Arrays = @import("arrays.zig");
const Utils = @import("utils.zig");


const Self = @This();
const IndexOfArena = u32;

arena_size: usize,
capacity_of_heap: usize,
arenas: []Arena,
treeped_arenas: RBTree,

archive_of_arenas: Arrays.runtime_static_array(IndexOfArena),
active_arenas: Arrays.runtime_static_array(IndexOfArena),
current_arenas: Arrays.runtime_static_array(IndexOfArena),

// pub fn alloc(self: *Self, size: usize) ?[*]u8 {
//
// }

pub const AllocatorError = error{InvalidConfig, OOMInInit, EmptyArchive, OOM, FreeOnManagedArena};

pub fn init(cfg: Config) AllocatorError!*Self {
	if (cfg.log_arena_size > cfg.log_capacity_of_heap)
		return AllocatorError.InvalidConfig;
	if (cfg.log_arena_size < 8) return AllocatorError.InvalidConfig;
	if (cfg.log_arena_size > 16) return AllocatorError.InvalidConfig;
	if ((1 << cfg.log_arena_size) < cfg.max_size_of_object_on_arena)
		return AllocatorError.InvalidConfig;

	const count_of_arenas = 1 << (cfg.log_capacity_of_heap - cfg.log_arena_size);
	var this = Self{};
	this.arena_size = 1 << cfg.log_arena_size;
	this.capacity_of_heap = 1 << cfg.log_capacity_of_heap;

	this.arenas = Utils.calloc(count_of_arenas, Arena)
		orelse return AllocatorError.OOMInInit;

	this.archive_of_arenas = Arrays.runtime_static_array(IndexOfArena).init(count_of_arenas)
		orelse return AllocatorError.OOMInInit;

	this.active_arenas = Arrays.runtime_static_array(IndexOfArena).init(count_of_arenas)
		orelse return AllocatorError.OOMInInit;

	this.current_arenas = Arrays.runtime_static_array(IndexOfArena).init(count_of_arenas)
		orelse return AllocatorError.OOMInInit;

	for (0..count_of_arenas) |i| {
		this.archive_of_arenas.push(count_of_arenas - i - 1);
	}
}

fn unarchive(self: *Self) AllocatorError!void {
	const new_arena = self.archive_of_arenas.pop()
		orelse return AllocatorError.EmptyArchive;

	self.active_arenas.push(new_arena);
	self.current_arenas.push(new_arena);

	// self.arenas[new_arena].
}