package frontend.typesystem

import core.typesystem.Type

import frontend.ast._
import scala.collection.mutable.HashMap
import scala.collection.mutable.Stack

type Label = String

// Not my proudest work.
//
// Should extend map or something in future i guess.
private class ScopedMap[T1, T2] private (scopes: Stack[HashMap[T1, T2]]) {
  def addOne(elem: (T1, T2)): ScopedMap[T1, T2] =
    scopes.top.addOne(elem)
    this
  def get(key: T1): Option[T2] = scopes.collectFirst {
    case hm if hm.contains(key) => hm(key)
  }
  def contains(key: T1): Boolean = get(key).isDefined
  def apply(key: T1) = get(key) match {
    case None => throw RuntimeException("NoSuchElementException") // lmao.
    case Some(value) => value
  }
  def iterator: Iterator[(T1, T2)] =
    scopes.iterator.flatMap(_.iterator)
  def scope(): ScopedMap[T1, T2] = {
    scopes.push(HashMap())
    this
  }
  def descope(): ScopedMap[T1, T2] = {
    scopes.pop()
    this
  }
  def print: Unit =
    scopes.foreach(println(_))
}

object ScopedMap {
  def apply[T1, T2](): ScopedMap[T1, T2] = new ScopedMap(Stack())
}

object RemovePlaceholders extends ASTPass {
  type Ctx = ScopedMap[Label, Type]
  private def Ctx(): Ctx = {
    val hm: Ctx = ScopedMap().scope()
    addPrimitives(using hm)
    hm
  }

  private def addPrimitives(using ctx: Ctx): Unit =
    Primitives.primitiveTypes.map(ctx.addOne(_))

  private def addDefine(e: Expr)(using ctx: Ctx): Expr = {
    e match {
      case Define(name, ty, body) => ctx.addOne(name -> ty)
      case Function(name, params, body, ty) => {
        val fnType = Type.Fn(params.map(_._2.getType), ty)
        ctx.addOne(name -> fnType)
      }
      case _ =>
    }
    e
  }

  private def typeVar(e: Expr)(using ctx: Ctx): Expr = e match {
    case Var(name, ty) =>
      if !ctx.contains(name) then
        ctx.print
        throw RuntimeException(s"usage of undefined variable $name")
      else Var(name, ctx(name))
    case e => e
  }

  private def composedFns(using ctx: Ctx): Expr => Expr =
    addDefine.andThen(typeVar)

  private def scope(fn: => Expr)(using ctx: Ctx): Expr = {
    ctx.scope()
    val res = fn
    ctx.descope()
    res
  }

  // TODO: Make map on Expr that allows for recursively mapping expressions instead of rewriting this each time.
  private def recursiveHelper(e: Expr)(using ctx: Ctx): Expr = {
    composedFns(scope(e match {
      case Define(name, ty, body) =>
        Define(name, ty, recursiveHelper(body))
      case Function(name, params, body, ty) =>
        Function(name, params, body.map(recursiveHelper), ty)
      case Call(function, args) =>
        // FIXME: incorrect assumptions
        // overloading is not working correctly. it gets the first "function" it can find.
        Call(recursiveHelper(function), args.map(recursiveHelper))
      case Block(body) =>
        Block(body.map(recursiveHelper))
      case e => e
    }))
  }

  def apply(v1: List[Expr]): List[Expr] = {
    val ctx = Ctx()
    given Ctx = ctx
    v1.map(addDefine(_))
    v1.map(recursiveHelper)
  }
}
