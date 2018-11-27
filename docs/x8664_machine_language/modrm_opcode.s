	.globl	main
main:
	add	$1, %eax
	or	$1, %eax
	adc	$1, %eax
	sbb	$1, %eax
	and	$1, %eax
	sub	$1, %eax
	xor	$1, %eax
	cmp	$1, %eax
	ret
