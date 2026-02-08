package frontend.lowering

import core.ir._
import core.ir
import frontend.ast._
import frontend.ast

import com.github.dwickern.macros.NameOf._
import core.ir.Var
import core.ir.Var
import core.ir.Var
import core.typesystem.Type

def log(str: => String): Unit = {
  println(str)
}

def logTranslation[T <: ast.Expr, Y <: ir.IR](f: T => Y, t: T): Unit = {
  log(s"translation method ${nameOf(f)} with parameter ${t.toString}")
}

class Namer {
  private var i: Int = 0
  def nameVar: String =
    "v" + i
}

def logThenExecuteTranslation[T <: ast.Expr, Y <: ir.IR](f: T => Y): T => Y = {
  t =>
    {
      logTranslation(f, t)
      f(t)
    }
}

trait Translator[T] {
  def translate(t: T): ir.Var
}

// TODO: adequate builder and constructors and stuff
class AstTranslator extends Translator[Expr] {
  private val namer = Namer()

  private def newVar(t: Type): ir.Var = ir.Var(namer.nameVar, t)

  private def translateConstInt(ci: ast.ConstInt) = {
    val ret = newVar(core.typesystem.Type.Int)
    Const(ret, ir.ConstInt(ci.i))
    ret
  }

  private def translateConstBool(cb: ast.ConstBool) = {
    val ret = newVar(core.typesystem.Type.Boolean)
    Const(ret, ir.ConstBool(cb.b))
    ret
  }

  private def translateVar(v: ast.Var) = {
    val newName = namer.nameVar
    log("mapped variable ${v.name} to ${newName}")
    ir.Var(newName, v.ty)
  }

  private def translateDefine(define: ast.Define) = {
    val newName = namer.nameVar
    val ret = ir.Var(newName, define.ty)
    ir.Mov(ret, translate(define))
    ret
  }

  def translateCall(call: ast.Call) = {
    ???
  }

  def translate(expr: Expr): ir.Var = {
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
