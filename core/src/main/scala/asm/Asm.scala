package core.asm.asm

// TODO: make it cross-platform

trait Asm

trait Instr

case class Program(header: Seq[Pragma])

trait Pragma extends Asm

case class Extern(label: Label) extends Pragma
case class Global(label: Label) extends Pragma

def extern(name: String): Extern = Extern(name)
def global(name: String): Global = Global(name)

given s2l: Conversion[String, Label] = Label(_)

case class Label(label: String) extends Asm

// TODO: make full-fledged memory operands
type Memory = Label

trait Immediate extends Asm

given i2imm: Conversion[Int, Imm64] = Imm64(_)

case class Imm64(i: Int) extends Immediate

case class Func(label: Label, instructions: Seq[Instr]) extends Asm
