package core.asm.register

sealed trait Register

case class RAX() extends Register
case class RBX() extends Register
case class RCX() extends Register
case class RDX() extends Register
case class RSI() extends Register
case class RDI() extends Register
case class RSP() extends Register
case class RBP() extends Register
case class R8() extends Register
case class R9() extends Register
case class R10() extends Register
case class R11() extends Register
case class R12() extends Register
case class R13() extends Register
case class R14() extends Register
case class R15() extends Register

def rax: Register = RAX()
def rbx: Register = RBX()
def rcx: Register = RCX()
def rdx: Register = RDX()
def rsi: Register = RSI()
def rdi: Register = RDI()
def rsp: Register = RSP()
def rbp: Register = RBP()
def r8: Register = R8()
def r9: Register = R9()
def r10: Register = R10()
def r11: Register = R11()
def r12: Register = R12()
def r13: Register = R13()
def r14: Register = R14()
def r15: Register = R15()
