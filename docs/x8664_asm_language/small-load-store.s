	# gcc -static -no-pie -Tbss=0x800000 small-load-store.s でビルドすること

	.globl main
main:
	mov	$0xff, %rax
	mov	%al, 0x800000 	# 1byte の 0xff を 0x800000 にストア
	movsxb	0x800000, %r8

	ret
