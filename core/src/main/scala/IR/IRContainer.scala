package core.ir

// TODO: move it to utils

type Container[T] = List[T]

def Container[T](): Container[T] = List()

trait IRContainer[T <: IR](protected var elems: Container[T] = Container()) {
  infix def add(elem: T): IRContainer[T] = {
    elems = elems.add(elem)
    this
  }
}

extension [T](c: Container[T]) {
  def add(element: T): Container[T] = {
    c.appended(element)
  }
}
