	.globl	main
main:
	mov $99, %rax
	mov %rax,0  		# アドレス0で識別される領域に、raxの値(99)を保存する
	mov 0, %r8 		# アドレス0で識別される領域から、値を取り出し、その値をr8に格納する
	ret
