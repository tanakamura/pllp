	.globl	_start
	.text
_start:
	incl	data0(%rip)
	mov	$60, %rax
	syscall

	.data
data0:
	.long	8
