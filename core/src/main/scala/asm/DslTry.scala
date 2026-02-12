package core.asm.dsltry

import core.asm.dsl._
import core.asm._
import core.asm.given
import core.asm.instructions._
import core.asm.register._

val start = func("_start") {
  mov(rax, 10)
  mov(rbx, 13)
}
