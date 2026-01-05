package core.ir

import core.typesystem.Type

sealed trait IR
sealed trait Label extends IR
sealed trait IRInstr extends IR
sealed trait IRTerm extends IR
sealed trait IRImm extends IR

// Once i write ilist it's gonna be ilist i think
type Container[T] = Vector[T]

// Labels:
case class Fn(name: String, params: Var, blocks: Container[Block]) extends Label

case class Block(name: String, stmts: Container[IRInstr]) extends Label

// Instructions:

case class Const(value: IRImm) extends IRInstr

// Binary instructions:

enum BinaryOp {
  case Add
  case Sub
  case Div
  case Mul
}

case class BinaryInstruction(
    res: Var,
    lhs: Var,
    rhs: Var,
    op: BinaryOp
) extends IRInstr

// Arguments:

case class Var(name: String, t: Type) extends IR

case class ConstInt(value: Int) extends IRImm

// Terminators:

case class Ret(value: Option[Var]) extends IRTerm
