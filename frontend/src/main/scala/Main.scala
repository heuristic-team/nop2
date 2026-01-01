package frontend

import frontend.parser._
import fastparse._

val test = """Int hello = {
    Bool hi = true
    Boris hi_ = 13 + hello
    hi_
  }
"""

@main def hello(): Unit =
  println(test)
  println(parse(test, expr(using _)))
