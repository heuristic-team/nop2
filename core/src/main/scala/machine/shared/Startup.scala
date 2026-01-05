package core.machine.shared

import core.ir.Fn

trait Startup {
  // All runtime setup code should be put there for exact arch.
  def _start: Fn
}
