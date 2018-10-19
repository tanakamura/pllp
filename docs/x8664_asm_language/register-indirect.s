	# gcc -static -no-pie -Tbss=0x800000 register-indrect.s のようにビルドする

	.globl	main
main:
	mov $0x99, %rax
	mov %rax, 0x800000      # 0x800000 に 0x99 をストア

	mov $0x800000, %rdx 	# RDX に整数値0x800000 を入れる
	mov (%rdx), %r8         # RDXの値(0x800000)をアドレスとして、メインメモリからロード
	
	ret
