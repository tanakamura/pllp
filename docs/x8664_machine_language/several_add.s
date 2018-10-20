	.globl	main
main:
	add %eax, %ecx
	add %eax, 0
	add %eax, (%rax)
	add %eax, (%rax,%rax)
	add %eax, 1(%rax,%rax)
	add %eax, 0x8000(%rax,%rax)
	ret
