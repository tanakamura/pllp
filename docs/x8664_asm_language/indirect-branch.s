	.globl	main
main:
	lea	loop, %rcx

	mov	$0, %rax

loop:
	add	$1, %rax
	jmp	*%rcx
