package frontend.ast

import frontend.typesystem.Type

sealed trait Expr

case class Call(functionName: Label, args: Container[Expr]) extends Expr

case class Function(
    name: Label,
    params: Container[Param],
    body: Container[Expr],
    `type`: Type
) extends Expr

case class ConstInt(i: Int) extends Expr

case class ConstBool(b: Boolean) extends Expr

case class Var(name: Label, `type`: Type) extends Expr

enum BinOpType {
  case Add
  case Sub
  case Mul
  case Div
  case CmpLe
  case CmpLt
  case CmpGt
  case CmpGe
  case CmpNe
  case CmpEq
}

case class BinaryOp(lhs: Expr, rhs: Expr, `type`: BinOpType) extends Expr
