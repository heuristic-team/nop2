package core.typesystem

enum `Type` {
  case Int
  case Boolean
  case Fn(from: List[Type], to: Type)
  case Custom(name: String)
  case Placeholder
  case Unit

  def arity: Int = this match {
    case Fn(from, to) => from.length
    case _            => 0
  }
}
