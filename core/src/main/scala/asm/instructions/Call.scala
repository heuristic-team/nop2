package core.asm.instructions

import core.asm.asm._
import core.asm.register._

sealed trait Call extends Instr

trait CallLabel(label: Label) extends Call

case class CallLabelx86(label: Label) extends CallLabel(label)

def call(label: Label): Call = CallLabelx86(label)
