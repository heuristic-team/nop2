package frontend.parser

import scala.util.Random

import org.scalatest._
import flatspec._
import matchers._

import fastparse._

import frontend.ast._
import frontend.typesystem.Type

class ParserSpec extends AnyFlatSpec with should.Matchers {
  def `var`: String => Var = Var(_, Type.Placeholder)
  def const: Int => ConstInt = ConstInt(_)
  def getInt: Int = {
    val int = Random().nextInt()
    if int < 0 then int * -1
    else int
  }

  "Integer" should "be parsed into ConstInt class" in {
    val int = getInt
    val intStr = int.toString
    parse(intStr, expr(using _)) should be(
      Parsed.Success(const(int), intStr.size)
    )
  }

  "Identifier" should "be parsed into Var class" in {
    val id = "_hello"
    parse(id, expr(using _)) should be(
      Parsed.Success(`var`(id), id.size)
    )
  }

  "Addition of two integers" should "be parsed into call of `+` function" in {
    val lhs = getInt
    val rhs = getInt
    val plus = "   + "
    val addition = lhs + plus + rhs
    parse(addition, expr(using _)) should be(
      Parsed.Success(
        Call(`var`(plus.trim()), List(const(lhs), const(rhs))),
        addition.size
      )
    )
  }
}
