	.globl main

main:
	mov	$0x11223344, %eax
	mov	$0x11223344, %ecx
	add	$0x11223344, %eax
	sub	$0x11223344, %eax

	ret
