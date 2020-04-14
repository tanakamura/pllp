	.globl	_start
	.text
_start:
	incl	data0
	mov	$60, %rax
	syscall

	.data
data0:
	.long	8
