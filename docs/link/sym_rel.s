	.globl	_start
	.text
_start:
	movabs	$_start, %rax
	mov	$_start, %eax
	jmp	_start

label0:
	nop
label1:
	nop
label2:
	nop
