package core.utils

class IListNode[T <: IListNode[T]] private (var prev: T, var next: T)

class IList[T <: IListNode[T]] private (head: T, tail: T)
