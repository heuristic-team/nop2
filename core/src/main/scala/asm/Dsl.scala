package core.asm.dsl

import scala.quoted.*
import core.asm._

inline def func(name: Label)(inline instrs: Instr): Func =
  Func(name, funcStage(instrs))

inline def funcStage(inline instrs: Instr): Seq[Instr] = ${
  funcMacro('instrs)
}

def funcMacro(instrs: Expr[Instr])(using Quotes): Expr[Seq[Instr]] =
  import quotes.reflect.*
  instrs.asTerm.underlyingArgument match {
    case Block(stats, last) =>
      val (defs, exprs) = stats.partition {
        case _: Definition => true
        case _: Term       => false
        case _             => true
      }

      val exprTerms = exprs.collect { case t: Term => t } :+ last

      if exprTerms.isEmpty then
        report.error("Func block must contain at least one instruction", instrs)
        '{ Seq() }
      else Expr.ofSeq(exprTerms.map(_.asExprOf[Instr]).toSeq)
    case other =>
      Expr.ofSeq(List(other.asExprOf[Instr]))
  }
