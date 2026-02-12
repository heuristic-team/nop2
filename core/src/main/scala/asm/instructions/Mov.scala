package core.asm.instructions

import core.asm._
import core.asm.register._

sealed trait Mov extends Instr

trait MovR64I64(r: Register, imm: Imm64) extends Mov

case class MovR64I64x86(r: Register, imm: Imm64) extends MovR64I64(r, imm)

def mov(r: Register, imm: Imm64): Mov = MovR64I64x86(r, imm)
