package frontend.ast

type Label = String
type Param = (Label, Expr)
type Container[T] = List[T]

def Container[T](ts: T*): Container[T] = List(ts*)

trait ASTPass extends (TranslationUnit => TranslationUnit) {
  def apply(v1: List[Expr]): List[Expr]
  def apply(tu: TranslationUnit): TranslationUnit =
    TranslationUnit(tu._1, apply(tu._2))
}
