package frontend.typesystem

// TODO: make it a part of semantic checks package and use it in backend too.

enum `Type` {
  case Int
  case Boolean
  case Fn(from: Type, to: Type)
}
