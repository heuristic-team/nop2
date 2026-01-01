package frontend.ast

import scala.collection.immutable.HashMap

import frontend.typesystem.Type

object Primitives {
  extension (list: List[Type]) {
    infix def ->(to: Type): Type =
      Type.Fn(list, to)
  }

  type Primitive = Expr
  // For now it is list for duplicates reasons. "+" can be (Int, Int) -> Int or (Float, Float) -> Float.
  type Mapping[T1, T2] = List[(T1, T2)]

  def Mapping[T1, T2](els: (T1, T2)*): Mapping[T1, T2] = List(els*)

  val primitiveTypes: Mapping[String, Type] = Mapping(
    "+" -> (Container(Type.Int, Type.Int) -> Type.Int),
    "-" -> (Container(Type.Int, Type.Int) -> Type.Int),
    "*" -> (Container(Type.Int, Type.Int) -> Type.Int),
    "/" -> (Container(Type.Int, Type.Int) -> Type.Int),
    "read" -> Type.Fn(Container(), Type.Int)
  )

}
