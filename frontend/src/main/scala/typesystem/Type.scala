package frontend.typesystem

// TODO: make it a part of semantic checks package and use it in backend too.

enum `Type` {
  case Int
  case Boolean
  case Fn(from: List[Type], to: Type)
  case Placeholder
  case Unit

  def arity: Option[Int] = this match {
    case Fn(from, to) => Some(from.length)
    case _            => None
  }
}
