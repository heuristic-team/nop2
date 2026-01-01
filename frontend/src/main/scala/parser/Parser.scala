package frontend.parser

import fastparse._, ScalaWhitespace._

import frontend.ast._
import scala.collection.mutable.HashMap
import frontend.typesystem.Type

trait Parser[T] {
  def parse(input: T): Expr
}

val defaultVar: String => Var = Var(_, Type.Placeholder)

def identifier[$: P]: P[String] = P(CharIn("_\\a-z\\A-Z").rep(1).!)

// TODO: 0x..., 0b..., floats, negative numbers. also booleans
def number[$: P]: P[Int] = P(CharIn("0-9").rep(1).!.map(_.toInt))
def const[$: P] = number.map(ConstInt(_))

def variable[$: P]: P[Var] =
  identifier.map(defaultVar)

def primaryExpression[$: P] =
  const | variable

def args[$: P]: P[List[Expr]] =
  P(expr.rep(sep = ",")).map(_.toList)

def callExpr[$: P]: P[Expr] =
  (primaryExpression ~ ("(" ~ args.? ~ ")").rep).map { (expr, calls) =>
    calls.foldLeft(expr)((acc, e) => Call(acc, e.getOrElse(Nil)))
  }

def divMul[$: P] = {
  P(callExpr ~ (CharIn("/*").! ~/ callExpr).rep).map { case (e, list) =>
    list.foldLeft(e) { case (lhs, (fname, rhs)) =>
      Call(defaultVar(fname), List(lhs, rhs))
    }
  }
}

def addSub[$: P] = {
  P(divMul ~ (CharIn("+\\-").! ~/ divMul).rep).map { case (e, list) =>
    list.foldLeft(e) { case (lhs, (fname, rhs)) =>
      Call(defaultVar(fname), List(lhs, rhs))
    }
  }
}

def expr[$: P] =
  addSub
