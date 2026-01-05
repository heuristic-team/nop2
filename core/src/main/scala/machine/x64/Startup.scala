package core.machine.x64

import core.ir.Fn
import core.machine.shared.Startup

class x64Startup extends Startup {
  def _start: Fn =
    Fn("_start", Vector(), Vector())
}
