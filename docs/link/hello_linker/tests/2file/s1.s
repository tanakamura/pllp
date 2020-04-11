	.text
	.globl	main

	.globl data1

main:
	mov	data0, %rax
	mov	data1, %rcx
	mov	data3, %rcx
	mov	data2, %rdx

	add	%rcx, %rax

	ret

data0:
	.long	1

	.data
data1:
	.long	2
data2:
	.long	data0
