package core.ir

import core.typesystem.Type

import scala.compiletime.uninitialized

trait WithOwner[T] {
  def owner: T
}

sealed trait IR

sealed trait Label extends IR

sealed trait IRInstr(block: Block) extends IR with WithOwner[Block] {
  def owner: Block = block
}

sealed trait ProduceValue {
  def result: Var
}

sealed trait Terminal

sealed trait IRImm extends IR

class CompilationUnit(ctx: CompilationContext) extends IR with IRContainer[Fn]

// Labels:
case class Fn(
    name: String,
    params: Container[Var] = Container()
)(using cu: CompilationUnit)
    extends Label
    with IRContainer[Block]
    with WithOwner[CompilationUnit] {

  def basicBlocks: Container[Block] = elems

  def owner: CompilationUnit = cu
}

case class Call(result: Var, function: Fn)(using
    block: Block
) extends IRInstr(block)
    with IRContainer[Var]
    with ProduceValue

case class Block(
    name: String
)(using fn: Fn)
    extends Label
    with IRContainer[IRInstr]

// Instructions:

case class Const(result: Var, value: IRImm)(using block: Block)
    extends IRInstr(block)
    with ProduceValue

// Binary instructions:

enum BinaryOp {
  case Add
  case Sub
  case Div
  case Mul
}

case class BinaryInstruction(result: Var, lhs: Var, rhs: Var, op: BinaryOp)(
    using block: Block
) extends IRInstr(block)
    with ProduceValue

case class Mov(result: Var, rhs: Var)(using block: Block)
    extends IRInstr(block)
    with ProduceValue

case class Read(result: Var)(using block: Block)
    extends IRInstr(block)
    with ProduceValue

// Arguments:

case class Var(name: String, t: Type) extends IR {
  var _owner: IRInstr = uninitialized
  def owner_=(instr: IRInstr): Unit =
    _owner = instr
  def owner: IRInstr = _owner
}

given ci2i: Conversion[ConstInt, Int] = _.value
given i2ci: Conversion[Int, ConstInt] = ConstInt(_)

case class ConstInt(value: Int) extends IRImm

given cb2b: Conversion[ConstBool, Boolean] = _.value
given b2cb: Conversion[Boolean, ConstBool] = ConstBool(_)

case class ConstBool(value: Boolean) extends IRImm

// Terminators:

case class Ret(value: Option[Var])(using block: Block)
    extends IRInstr(block)
    with Terminal
