	.globl	main
main:
	add %eax, (%rax)
	add %ecx, (%rax)
	add %edx, (%rax)
	add %ebx, (%rax)

	add %esp, (%rax)
	add %ebp, (%rax)
	add %esi, (%rax)
	add %edi, (%rax)

	ret
