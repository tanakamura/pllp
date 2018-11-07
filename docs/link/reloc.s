	.globl	_start
_start:
	movl	$ref_32bit, %eax # 32bitアドレスを参照
	movl	$ref_32bit + 32, %eax # 32bitアドレスを参照

	movq	$ref_64bit, %rax # 32bit or 64bit アドレスを参照

	jmp	ref_as_jmp_label # PC 相対アドレスを参照

	mov	$60, %rax
	syscall

	.quad	ref_64bit  	# 64bitアドレスを参照
	.long	ref_32bit	# 32bitアドレスを参照
