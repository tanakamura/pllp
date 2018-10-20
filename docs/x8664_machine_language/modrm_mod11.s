	.globl	main
main:
	add %eax, %eax
	add %eax, %ecx
	add %eax, %edx
	add %eax, %ebx

	add %eax, %esp
	add %eax, %ebp
	add %eax, %esi
	add %eax, %edi

	.byte	0x01		# add %r32, r/m32
	.byte	0xc0		# mod=11, reg=00, r/m=00

	.byte	0x03		# add r/m32, %r32
	.byte	0xc0		# mod=11, reg=00, r/m=00

	ret
