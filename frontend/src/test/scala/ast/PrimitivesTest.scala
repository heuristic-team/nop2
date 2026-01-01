package frontend.ast

import scala.util.Random

import org.scalatest._
import flatspec._
import matchers._

import fastparse._

import frontend.parser._
import frontend.typesystem.Type
// println(parse("hello(1 + 2)(hi)", expr(using _)))

class ParserSpec extends AnyFlatSpec with should.Matchers {
  def `var`: String => Var = Var(_, Type.Placeholder)
  def const: Int => ConstInt = ConstInt(_)
  def getInt: Int = {
    val int = Random().nextInt()
    if int < 0 then int * -1
    else int
  }

  "Integer" should "not be primitive" in {
    ConstInt(getInt).isPrimitive should be(false)
  }

  "Identifier" should "not be primitive" in {
    `var`("hello_").isPrimitive should be(false)
  }

  "Addition of two integers" should "be primitive" in {
    val lhs = const(getInt)
    val rhs = const(getInt)
    val add = Call(`var`("+"), List(lhs, rhs))
    add.isPrimitive should be(true)
  }
}
