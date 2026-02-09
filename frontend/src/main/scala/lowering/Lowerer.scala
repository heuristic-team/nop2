package frontend.lowering

import core.ir._
import core.ir
import frontend.ast._
import frontend.ast

import com.github.dwickern.macros.NameOf._
import core.typesystem.Type

import scala.compiletime.uninitialized
import core.ir.Block

def log(str: => String): Unit = {
  println(str)
}

def logTranslation[T <: ast.Expr, Y <: ir.IR](f: T => Y, t: T): Unit = {
  log(s"translation method ${nameOf(f)} with parameter ${t.toString}")
}

class Namer {
  private var i: Int = 0
  private var b: Int = 0

  def nameVar: String = {
    i += 1
    "v" + i
  }

  def nameBlock: String = {
    b += 1
    "L" + b
  }

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

// TODO: adequate builder and constructors and stuff
class AstTranslator extends Translator[TranslationUnit] {
  case class Ctx(currentFn: Fn, currentBlock: Block)

  given currentBlock(using ctx: Ctx): Block = ctx.currentBlock
  given currentFn(using ctx: Ctx): Fn = ctx.currentFn

  private val namer = Namer()

  private def newVar(t: Type): ir.Var = ir.Var(namer.nameVar, t)

  def fn(using ctx: Ctx): ir.Fn = ctx.currentFn

  def block(using ctx: Ctx): ir.Block = ctx.currentBlock

  private def translateConstInt(ci: ast.ConstInt)(using ctx: Ctx) = {
    val ret = newVar(core.typesystem.Type.Int)
    Const(ret, ir.ConstInt(ci.i))
    ret
  }

  private def translateConstBool(cb: ast.ConstBool)(using ctx: Ctx) = {
    val ret = newVar(core.typesystem.Type.Boolean)
    Const(ret, ir.ConstBool(cb.b))
    ret
  }

  private def translateVar(v: ast.Var)(using ctx: Ctx) = {
    val newName = namer.nameVar
    log("mapped variable ${v.name} to ${newName}")
    ir.Var(newName, v.ty)
  }

  private def translateDefine(define: ast.Define)(using ctx: Ctx) = {
    val newName = namer.nameVar
    val ret = ir.Var(newName, define.ty)
    block add ir.Mov(ret, translate(define))
    ret
  }

  private def translatePrimitiveCall(call: ast.Call): ir.Var = { ??? }

  private def translateCall(call: ast.Call)(using ctx: Ctx): ir.Var = {
    if !call.isPrimitive then
      throw IllegalArgumentException("only primitive calls are allowed for now")

    ???
  }

  def translate(t: TranslationUnit): CompilationUnit = ???

  def translate(expr: Expr)(using ctx: Ctx): ir.Var = {
    expr match {
      case b: ast.Block     => ???
      case ci: ast.ConstInt => logThenExecuteTranslation(translateConstInt)(ci)
      case cb: ast.ConstBool =>
        logThenExecuteTranslation(translateConstBool)(cb)
      case v: ast.Var => logThenExecuteTranslation(translateVar)(v)
      case c: ast.Call =>
        logThenExecuteTranslation(translateCall)(c)
      case d: ast.Define   => logThenExecuteTranslation(translateDefine)(d)
      case f: ast.Function => ???
    }
  }
}
