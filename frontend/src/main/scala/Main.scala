package frontend

import frontend.parser._
import fastparse._
import frontend.typesystem.DummyIntPass
import fastparse.Parsed.Failure
import fastparse.Parsed.Success
import frontend.typesystem.RemovePlaceholders

val test = """Int hello = {
    Bool hi = 13
    Int hi_ = 13 + hello
    hi
    hi_
}

Int hi = 1u

148
"""

@main def hello(): Unit = {
  println(test)
  val tu = parse(test, program("test")(using _))
  val t = tu match {
    case f: Failure =>
      println("Parsing failed: $f")
      throw RuntimeException("Parsing failed. Compiler exits.")
    case Success(value, index) => value
  }
  val translation_unit = RemovePlaceholders(t)
  println(translation_unit)
}
