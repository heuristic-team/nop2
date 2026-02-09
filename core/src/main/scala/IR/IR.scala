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

sealed trait Terminal

sealed trait IRImm extends IR with WithOwner[IRInstr] {
  var _owner: IRInstr = uninitialized
  def owner_=(instr: IRInstr): Unit =
    _owner = instr
  def owner: IRInstr = _owner
}

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

case class Call(res: Var, function: Fn)(using
    block: Block
) extends IRInstr(block)
    with IRContainer[Var]

case class Block(
    name: String
)(using fn: Fn)
    extends Label
    with IRContainer[IRInstr]

// Instructions:

case class Const(res: Var, value: IRImm)(using block: Block)
    extends IRInstr(block)

// Binary instructions:

enum BinaryOp {
  case Add
  case Sub
  case Div
  case Mul
}

case class BinaryInstruction(res: Var, lhs: Var, rhs: Var, op: BinaryOp)(using
    block: Block
) extends IRInstr(block)

case class Mov(lhs: Var, rhs: Var)(using block: Block) extends IRInstr(block)

case class Read(res: Var)(using block: Block) extends IRInstr(block)

// Arguments:

case class Var(name: String, t: Type) extends IR

case class ConstInt(value: Int) extends IRImm

case class ConstBool(value: Boolean) extends IRImm

// Terminators:

case class Ret(value: Option[Var])(using block: Block)
    extends IRInstr(block)
    with Terminal
