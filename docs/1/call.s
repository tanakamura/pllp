	.globl main

func:
	add	$1, %rax
	ret

main:
	mov	$0, %rax
	call	func
	call	func
	call	func
	ret
