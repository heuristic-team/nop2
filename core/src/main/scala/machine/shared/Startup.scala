package core.machine.shared

import core.ir.Fn

trait Startup {
  // All runtime setup code should be put there for exact arch.
  // TODO: create hook for language to setup runtime code, provide default one with libc.
  def _start: Fn
}
