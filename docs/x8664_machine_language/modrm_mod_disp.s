	.globl	main
main:
	mov (%rax), %ecx 	# mod=0b00, r/m=0b000(ax), disp=0(0bit)
	mov 1(%rax), %ecx	# mod=0b01, r/m=0b000(ax), disp=1(8bit)
	mov 256(%rax), %ecx	# mod=0b10, r/m=0b000(ax), disp=256(32bit)

	ret
