const Utils = @import("utils.zig");


pub fn linked_list(comptime T: type, comptime Allocator: type) type {
  return struct {
    const Self = @This();

    pub const Node = struct {
      data: T,
      next: ?*Node = null,

      pub fn init(data: T) Node {
        return Node{ .data = data };
      }
    };

    allocator: Allocator,
    head: ?*Node = null,
    tail: ?*Node = null,
    len:  usize  = 0,

    pub fn init(allocator: Allocator) Self {
      return Self{
        .allocator = allocator,
      };
    }

    pub fn deinit(self: *Self) void {
      var current = self.head;
      while (current) |node| {
        const next = node.next;
        self.allocator.free(node);
        current = next;
      }
      self.head = null;
      self.tail = null;
      self.len  = 0;
    }

    pub fn append(self: *Self, data: T) !void {
      const new_node: *Node = try self.allocator.new(Node);
      new_node.* = Node.init(data);

      if (self.head == null) {
        self.head = new_node;
        self.tail = new_node;
      } else {
        self.tail.?.next = new_node;
        self.tail = new_node;
      }
      self.len += 1;
    }

    pub fn prepend(self: *Self, data: T) !void {
      const new_node: *Node = try self.allocator.new(Node);
      new_node.* = Node.init(data);
      new_node.next = self.head;

      self.head = new_node;
      if (self.tail == null) {
        self.tail = new_node;
      }
      self.len += 1;
    }

    pub fn isEmpty(self: *Self) bool {
      return self.head == null;
    }

    pub fn clear(self: *Self) void {
      self.deinit();
    }

    pub const Iterator = struct {
      current: ?*Node,

      pub fn next(self: *Iterator) ?T {
        if (self.current) |node| {
          const data = node.data;
          self.current = node.next;
          return data;
        }
        return null;
      }
    };

    pub fn iterator(self: *Self) Iterator {
      return Iterator{ .current = self.head };
    }
  };
}