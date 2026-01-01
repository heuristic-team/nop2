package frontend.ast

type Label = String
type Param = (Label, Expr)
type Container[T] = List[T]

def Container[T](ts: T*): Container[T] = List(ts*)
