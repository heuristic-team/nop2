package frontend.ast

import frontend.typesystem.Type

sealed trait Expr

case class Call(function: Expr, args: Container[Expr]) extends Expr

case class Function(
    name: Label,
    params: Container[Param],
    body: Container[Expr],
    ty: Type
) extends Expr

case class ConstInt(i: Int) extends Expr

case class ConstBool(b: Boolean) extends Expr

case class Var(name: Label, ty: Type) extends Expr
