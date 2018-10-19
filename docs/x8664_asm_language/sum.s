	.globl main

main:
	mov	$10, %rcx
	mov	$0, %rax

loop:
	add	%rcx, %rax
	sub	$1, %rcx
	jnz	loop

end:
	ret
