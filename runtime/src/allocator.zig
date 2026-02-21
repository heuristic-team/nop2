const AllocatorConfig = @import("allocator_config.zig");
const Arena = @import("arena.zig");
const RBTree = @import("rbtree.zig").rbtree;
const Arrays = @import("arrays.zig");
const Utils = @import("utils.zig");
const LinkedList = @import("linked_list.zig").linked_list;


const Self = @This();
const IndexOfArena = u32;

arena_size: usize,
capacity_of_heap: usize,
managed_arenas: LinkedList(*Arena, *Arena),
treeped_managed_arenas: RBTree(*Arena),
arenas_for_rebuild: LinkedList(*Arena, *Arena),
native_arenas: LinkedList(*Arena, *Arena),
treeped_native_arenas: RBTree(*Arena),
boot_arena: Arena,
boot_allocator: *Self = null,

// pub fn alloc(self: *Self, size: usize) ?[*]u8 {
//
// }

pub const AllocatorError = error{InvalidConfig, OOMInInit, EmptyArchive, OOM, FreeOnManagedArena, PageSizeIsNotSupport, ArenaSizeIsLarge};


pub fn init(cfg: AllocatorConfig) AllocatorError!*Self {
  const page_size = Utils.get_page_size();
  if (page_size > Arena.MAX_SUPPORT_PAGE_SIZE) return AllocatorError.PageSizeIsNotSupport;

	if (1 << cfg.log_arena_size > cfg.capacity_of_heap)
		return AllocatorError.InvalidConfig;
	if (cfg.log_arena_size < 8) return AllocatorError.InvalidConfig;
	if (cfg.log_arena_size > 16) return AllocatorError.InvalidConfig;
	if ((1 << cfg.log_arena_size) < cfg.max_size_of_object_on_arena)
		return AllocatorError.InvalidConfig;

	var this = Self{};
	this.arena_size = 1 << cfg.log_arena_size;
	this.capacity_of_heap = 1 << cfg.log_capacity_of_heap;

  this.boot_arena = Arena{};
  const count_of_arenas = cfg.capacity_of_heap / (1 << cfg.log_arena_size);
  const predict = Utils.roundUpToN(count_of_arenas * 256, page_size);
  this.boot_arena.init(predict, false, true) catch |err| switch (err) {

    error.ArenaSizeIsLarge => {
      try this.boot_arena.init(page_size, false, true);
      this.boot_allocator = try this.boot_arena.new(Self);
      this.boot_allocator.* = Self.init(AllocatorConfig{
        .capacity_of_heap = predict,
        .log_arena_size = 16,
        .max_size_of_object_on_arena = predict / 4
      });
    },

    else => return err
  };

}
