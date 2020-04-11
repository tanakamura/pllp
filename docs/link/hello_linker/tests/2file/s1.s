	.text
	.globl	main

	.globl data0
	.globl data1

main:
	movl	data0, %eax
	movq	data1_addr, %rcx
	movl	(%rcx), %ecx

	leaq	data0, %rdx

	addl	%ecx, %eax

	movl	%eax, result

	ret

	.data
data0:
	.long	1

	.section .rodata
data1_addr:
	.quad	data1

	.bss
result:
	.space	4
