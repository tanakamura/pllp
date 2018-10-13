	.globl main

func:
	add	$1, %rax
	ret

func2:
	call	func
	ret

func3:
	call	func2
	ret

main:
	mov	$0, %rax
	call	func
	call	func3
	ret
