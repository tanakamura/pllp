	.globl	_start
_start:
	movl	$ref_32bit, %eax # 32bitラベルを参照
	movw	$ref_16bit, %ax	 # 16bitラベルを参照
	movb	$ref_8bit, %al   # 8bitラベルを参照
	jmp	ref_as_jmp_label # PC 相対アドレスを参照

	movl	$ref_32bit + 32, %eax # オフセット付き

	mov	$60, %rax
	syscall

