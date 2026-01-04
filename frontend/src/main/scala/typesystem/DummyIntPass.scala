package frontend.typesystem

import core.typesystem.Type

import frontend.ast._

object DummyIntPass extends ASTPass {
  private def recursiveHelper(expr: Expr): Expr = expr match {
    case Block(body)   => Block(body.map(recursiveHelper))
    case Var(name, ty) => Var(name, Type.Int)
    case Call(function, args) =>
      Call(function, args.map(recursiveHelper))
    case Function(name, params, body, ty) =>
      Function(name, params, body.map(recursiveHelper), ty)
    case Define(name, ty, body) =>
      Define(name, ty, recursiveHelper(body))
    case expr => expr
  }
  def apply(list: List[Expr]): List[Expr] = list.map(recursiveHelper)
}
