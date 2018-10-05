	.globl	main
main:
	mov $1, %rax
	mov $2, %r8
	sub %r8, %rax

	mov $3, %rax
	mov $4, %r8
	imul %r8, %rax

	mov $0xaa, %rax
	mov $0x0f, %r8
	and %r8, %rax

	mov $0xaa, %rax
	mov $0x0f, %r8
	or %r8, %rax

	mov $0xaa, %rax
	mov $0x0f, %r8
	xor %r8, %rax

	ret
