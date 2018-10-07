	# gcc -static -no-pie -Tbss=0x800000 address-arith.s のようにビルドする

	.globl	main
main:
	mov $0, %r8         # %r8 ゼロ初期化
	mov $0, %r9         # %r9 ゼロ初期化

	movb $0x0, 0x800000 # 0x800000 から順番に 8個データを保存
	movb $0x1, 0x800001
	movb $0x2, 0x800002
	movb $0x3, 0x800003

	mov $0x800000, %rax # %rax に整数値0x800000を格納
	movsxb (%rax), %r9
	add %r9, %r8
	add $1, %rax

	movsxb (%rax), %r9
	add %r9, %r8
	add $1, %rax

	movsxb (%rax), %r9
	add %r9, %r8
	add $1, %rax

	movsxb (%rax), %r9
	add %r9, %r8
	
	ret
