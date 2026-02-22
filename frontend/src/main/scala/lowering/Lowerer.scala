package frontend.lowering

import core.ir._
import core.ir
import frontend.ast._
import frontend.ast
import frontend.lowering.given

import com.github.dwickern.macros.NameOf._
import core.typesystem.Type

import scala.compiletime.uninitialized
import scala.collection.mutable.HashMap

val loggingEnabled = true

// TODO: make logging great (again? when was the first time?)
def log(str: => String): Unit = {
  if loggingEnabled then println(str)
}

def logTranslation[T <: ast.Expr, Y <: ir.IR](f: T => Y, t: T): Unit = {
  log(s"translation method ${nameOf(f)} with parameter ${t.toString}")
}

def logThenExecuteTranslation[T <: ast.Expr, Y <: ir.IR](f: T => Y): T => Y = {
  t =>
    {
      logTranslation(f, t)
      f(t)
    }
}

trait Translator[T] {
  def translate(t: T): IR
}

type MethodDefinition = (ast.Label, Type)

case class AstTranslatorCtx(
    currentFn: Fn,
    currentBlock: ir.Block
) {}

class AstTranslator extends Translator[TranslationUnit] {
  given currentBlock(using ctx: AstTranslatorCtx): ir.Block = ctx.currentBlock
  given currentFn(using ctx: AstTranslatorCtx): Fn = ctx.currentFn

  private def translate(ci: ast.ConstInt)(using ctx: AstTranslatorCtx) =
    IRFactory.constInt(ci.i)

  private def translate(cb: ast.ConstBool)(using
      ctx: AstTranslatorCtx
  ) = IRFactory.constBool(cb.b)

  private def translate(v: ast.Var)(using ctx: AstTranslatorCtx) = {
    ir.Var(v.name, v.ty)
  }

  private def translatePrimitiveCall(call: ast.Call): ir.Var = { ??? }

  private def translate(
      call: ast.Call
  )(using ctx: AstTranslatorCtx): ir.Var = {
    if !call.isPrimitive then
      throw IllegalArgumentException("only primitive calls are allowed for now")
    call.args.map(translate(_))

    ???
  }

  private def translate(
      block: ast.Block
  )(using ctx: AstTranslatorCtx): ir.Var = block.body.map(translate(_)).last

  def translate(d: ast.Define)(using ctx: AstTranslatorCtx): ir.Var =
    IRFactory.define(d.name, translate(d.body), d.getType)

  def translate(t: TranslationUnit): CompilationUnit = ???

  private def translating[T <: ast.Expr](v: T)(using
      ctx: AstTranslatorCtx
  ): ir.Var =
    logThenExecuteTranslation(translate: T => ir.Var)(v)

  def translate(expr: Expr)(using ctx: AstTranslatorCtx): ir.Var = {
    expr match {
      case b: ast.Block =>
        translating(b)
      case ci: ast.ConstInt =>
        translating(ci)
      case cb: ast.ConstBool =>
        translating(cb)
      case v: ast.Var =>
        translating(v)
      case c: ast.Call =>
        translating(c)
      case d: ast.Define =>
        translating(d)
      case f: ast.Function => ???
    }
  }
}
