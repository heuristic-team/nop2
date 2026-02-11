package core.asm

trait Asm

trait Instr

case class Program(header: Seq[Pragma])

trait Pragma extends Asm

case class Extern(label: Label) extends Pragma
case class Global(label: Label) extends Pragma

case class Label(label: String) extends Asm

trait Immediate extends Asm

case class Imm64(i: Int) extends Immediate

case class Func(label: Label, instructions: Seq[Instr]) extends Asm
