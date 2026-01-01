package frontend

import frontend.parser._
import fastparse._

val test = """Int hello = {
    Bool hi = true
    Boris hi_ = 13 + hello
    hi_
}

Int hi = 13

148
"""

@main def hello(): Unit =
  println(test)
  println(parse(test, program("test")(using _)))
