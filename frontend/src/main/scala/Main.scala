package frontend

import frontend.parser._
import fastparse._
import frontend.typesystem.DummyIntPass
import fastparse.Parsed.Failure
import fastparse.Parsed.Success

val test = """Int hello = {
    Bool hi = true
    Boris hi_ = 13 + hello
    hi_
}

Int hi = 13

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
  val translation_unit = DummyIntPass(t)
  println(translation_unit)
}
