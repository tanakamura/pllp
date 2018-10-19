	.globl	main
main:
	mov	$0, %rax

loop:
	add	$1, %rax
	jmp	loop
