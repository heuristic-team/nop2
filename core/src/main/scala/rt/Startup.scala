package rt.startup

import core.asm._
import core.asm.asm._
import core.asm.dsl._
import core.asm.asm.given
import core.asm.register._
import core.asm.instructions._

val externs = Seq(
  extern("__rt_init"),
  extern("__alloc"),
  global("_start"),
  global("main")
)

val startup = func("_start") {
  mov(rdi, "main")
  mov(rsi, "spd")
  mov(rdx, rsp)
  call("__rt_init")
}
