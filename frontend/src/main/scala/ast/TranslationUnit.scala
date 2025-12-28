package frontend.ast

trait TUCtx {
  def entryPoint: Label
  def fileName: String
}

class DefaultTUCtx private (ep: Label, fn: String) extends TUCtx {
  def entryPoint: Label = ep
  def fileName: String = fn
}

object DefaultTUCtx {
  private val standardEntryPoint = "main"
  def apply(fileName: String): DefaultTUCtx =
    new DefaultTUCtx(standardEntryPoint, fileName)
  def apply(entryPoint: Label, fileName: String): DefaultTUCtx =
    new DefaultTUCtx(entryPoint, fileName)
}

case class TranslationUnit(ctx: TUCtx, exprs: Container[Expr])
