	.globl	main
main:
	mov (%rbp), %ecx 	# mod=0b01, r/m=0b101, disp=0(8bit)
	mov 1(%rbp), %ecx	# mod=0b01, r/m=0b101, disp=1(8bit)
	mov 256(%rbp), %ecx	# mod=0b10, r/m=0b101, disp=256(32bit)

	## 0x80000からロード
	mov 0x80000, %ecx  	# mod=0b00, r/m=0b101

	ret
