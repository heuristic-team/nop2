package core.asm.instructions

import core.asm._

sealed trait Mov extends Instr

class MovRegImm64(r: Register, imm: Imm64) extends Mov
