package frontend.lowering

import core.ir
import core.ir._
import core.ir.given
import core.typesystem.*

object IRFactory {
  private class Namer {
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

  given currentBlock(using ctx: AstTranslatorCtx): Block = ctx.currentBlock
  given currentFn(using ctx: AstTranslatorCtx): Fn = ctx.currentFn

  def fn(using ctx: AstTranslatorCtx): ir.Fn = ctx.currentFn

  def block(using ctx: AstTranslatorCtx): ir.Block = ctx.currentBlock

  def blockAdd(instr: => IRInstr)(using block: Block): Unit = block.add(instr)

  def producingInstr(v: Var, f: Var => IRInstr): IRInstr = {
    val instr = f(v)
    v.owner = instr
    instr
  }

  private val namer = Namer()

  private def newVar(t: Type): Var = Var(namer.nameVar, t)

  private def const[A](a: A, t: Type, f: A => IRImm)(using
      block: Block
  ): Var = {
    val variable = newVar(t)
    val instr = blockAdd(producingInstr(variable, Const(_, f(a))))
    variable
  }

  def constInt(i: Int)(using block: Block): Var =
    const(i, Type.Int, ConstInt(_))

  def constBool(b: Boolean)(using block: Block): Var =
    const(b, Type.Boolean, ConstBool(_))

  def define(l: frontend.ast.Label, e: Var, t: Type)(using
      ctx: AstTranslatorCtx
  ): Var = {
    val variable = Var(l, t)
    val instr = blockAdd(producingInstr(variable, Mov(_, e)))
    variable
  }
}
