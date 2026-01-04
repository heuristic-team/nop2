package core.ir

trait IR
trait Label
trait IRStmt
trait IRArgument

type Container[T] = Vector[T]

case class Fn(name: String, params: Var, blocks: Container[Block]) extends IR with Label

case class Block(name: String, stmts: Container[IRStmt]) extends IR with Label

// TODO: types to backend.
case class Var(name: String) extends IRArgument
