package core.ir

import core.typesystem.Type

sealed trait IR
sealed trait Label extends IR
sealed trait IRInstr extends IR
sealed trait IRTerm extends IR
sealed trait IRImm extends IR

type Container[T] = List[T]

// Labels:
case class Fn(name: String, params: Container[Var], blocks: Container[Block])
    extends Label

case class Call(function: Fn, args: Container[Var]) extends IRInstr

case class Block(name: String, stmts: Container[IRInstr]) extends Label

// Instructions:

case class Const(res: Var, value: IRImm) extends IRInstr

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

case class Mov(lhs: Var, rhs: Var) extends IRInstr

// Arguments:

case class Var(name: String, t: Type) extends IR

case class ConstInt(value: Int) extends IRImm

case class ConstBool(value: Boolean) extends IRImm

// Terminators:

case class Ret(value: Option[Var]) extends IRTerm
