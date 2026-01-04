package frontend.parser

import fastparse._, ScalaWhitespace._

import core.typesystem.Type

import frontend.ast._
import scala.collection.mutable.HashMap

val defaultVar: String => Var = Var(_, Type.Placeholder)

def identifier[$: P]: P[String] = P(CharIn("_\\a-z\\A-Z").repX(1).!)

// TODO: 0x..., 0b..., floats, negative numbers. also booleans
def number[$: P]: P[Int] = P(CharIn("0-9").repX(1).!.map(_.toInt))
def const[$: P] = number.map(ConstInt(_))

def variable[$: P]: P[Var] =
  identifier.map(defaultVar)

def primaryExpression[$: P] =
  const | variable

def seqToContainer[T]: Seq[T] => Container[T] = _.toList

def args[$: P]: P[List[Expr]] =
  P(expr.rep(sep = ",")).map(seqToContainer)

def callExpr[$: P]: P[Expr] =
  (primaryExpression ~ ("(" ~ args.? ~ ")").rep).map { (expr, calls) =>
    calls.foldLeft(expr)((acc, e) => Call(acc, e.getOrElse(Nil)))
  }

def divMul[$: P] = {
  P(callExpr ~ (CharIn("/*").! ~/ callExpr).rep).map { case (e, list) =>
    list.foldLeft(e) { case (lhs, (fname, rhs)) =>
      Call(defaultVar(fname), Container(lhs, rhs))
    }
  }
}

def addSub[$: P] = {
  P(divMul ~ (CharIn("+\\-").! ~/ divMul).rep).map { case (e, list) =>
    list.foldLeft(e) { case (lhs, (fname, rhs)) =>
      Call(defaultVar(fname), Container(lhs, rhs))
    }
  }
}

def types[$: P] =
  identifier.map { str =>
    str match {
      case "Int"  => Type.Int
      case "Bool" => Type.Boolean
      case s      => Type.Custom(s)
    }
  }

def define[$: P]: P[Expr] =
  P(types ~ identifier ~ "=" ~ expr).map((t, id, e) => Define(id, t, e))

def block[$: P]: P[Expr] =
  ("{" ~ expr.rep ~ "}").map(s => Block(s.toList))

def expr[$: P] =
  block | define | addSub

def program(fileName: String)[$: P] =
  expr.rep.map(s => TranslationUnit(DefaultTUCtx(fileName), s.toList))
