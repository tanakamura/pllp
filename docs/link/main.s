	.globl	main
main:
	lea	0(%rip), %rax
	call	printf
	ret
