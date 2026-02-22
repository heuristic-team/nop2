package core.asm.instructions

import core.asm.asm._
import core.asm.register._

sealed trait Mov extends Instr

trait MovR64I64(r: Register, imm: Imm64) extends Mov

trait MovR64R64(r1: Register, r2: Register) extends Mov

trait MovR64M(r: Register, imm: Memory) extends Mov

case class MovR64I64x86(r: Register, imm: Imm64) extends MovR64I64(r, imm)

case class MovR64R64x86(r1: Register, r2: Register) extends MovR64R64(r1, r2)

case class MovR64Mx86(r: Register, mem: Memory) extends MovR64M(r, mem)

def mov(r: Register, imm: Imm64): Mov = MovR64I64x86(r, imm)
def mov(r: Register, label: Label): Mov = MovR64Mx86(r, label)
def mov(r1: Register, r2: Register): Mov = MovR64R64x86(r1, r2)
