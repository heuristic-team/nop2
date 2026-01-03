package frontend.ast

import scala.collection.immutable.HashMap

import frontend.typesystem.Type

object Primitives {
  extension (list: Container[Type]) {
    infix def ->(to: Type): Type =
      Type.Fn(list, to)
  }

  given t22container[T]: Conversion[(T, T), Container[T]] with
    def apply(x: (T, T)): List[T] = Container(x._1, x._2)

  type Primitive = Expr
  // For now it is list for duplicates reasons. "+" can be (Int, Int) -> Int or (Float, Float) -> Float.
  type Mapping[T1, T2] = List[(T1, T2)]

  def Mapping[T1, T2](els: (T1, T2)*): Mapping[T1, T2] = List(els*)

  val primitiveTypes: Mapping[String, Type] = Mapping(
    "+" -> ((Type.Int, Type.Int) -> Type.Int),
    "-" -> ((Type.Int, Type.Int) -> Type.Int),
    "*" -> ((Type.Int, Type.Int) -> Type.Int),
    "/" -> ((Type.Int, Type.Int) -> Type.Int),
    "read" -> (Container() -> Type.Int)
  )

  val primitiveArgTypes: Mapping[String, List[Type]] =
    primitiveTypes.map { (str, t) =>
      t match {
        case Type.Fn(from, to) => (str, from)
        case _ =>
          throw RuntimeException(
            s"primitive is not a function but $t for some reason."
          )
      }
    }

}
