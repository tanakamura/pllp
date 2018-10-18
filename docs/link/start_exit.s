	.globl	_start

_start:
	call	main
	mov	$60, %rax
	syscall

main:
	ret

