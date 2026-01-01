package frontend

import frontend.parser._
import fastparse._

@main def hello(): Unit =
  println(parse("hello(1 + 2)(hi)", expr(using _)))
