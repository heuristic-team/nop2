package frontend.ast

import frontend.typesystem.Type

sealed trait Expr {
  def getType: Type
}

case class Call(function: Expr, args: Container[Expr]) extends Expr {
  def getType: Type = function.getType match {
    case Type.Fn(from, to) => to
    case Type.Placeholder =>
      throw RuntimeException("getType on untyped expression.")
    case t => throw RuntimeException("expected: Type.Fn, got: " + t)
  }

  def isPrimitive: Boolean = {
    val name = function match {
      case Var(name, ty) => name
      case _             => false
    }
    val pat = Primitives.primitiveArgTypes
    val currentArgumentTypes = args.map(_.getType)
    pat.find { (fname, argTypes) =>
      fname == name && argTypes == currentArgumentTypes
    }.isDefined
  }
}

case class Function(
    name: Label,
    params: Container[Param],
    body: Container[Expr],
    ty: Type
) extends Expr {
  def getType: Type = Type.Unit
}

case class ConstInt(i: Int) extends Expr {
  def getType: Type = Type.Int
}

case class ConstBool(b: Boolean) extends Expr {
  def getType: Type = Type.Boolean
}

case class Var(name: Label, ty: Type) extends Expr {
  def getType: Type = ty
}
