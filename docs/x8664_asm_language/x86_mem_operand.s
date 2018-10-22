	# gcc -static -no-pie -Tbss=0x800000 x86_mem_operand.s のようにビルドすれば、0x800000 のアドレスに
	# メインメモリがOSから割り当てられた状態でプログラムが起動する実行ファイルを作ることができる

	.globl	main
main:
	mov $0x99, %rax
	mov %rax, 0x800000 # アドレス0x800000で識別される領域に、raxの値(99)を保存する

	mov $0x200000, %rax
	mov $0x100000, %rcx
	mov 0x400000(%rax,%rcx,2), %r8 #0x400000 + 0x20000(rax) + 0x100000(rcx)*2 = 0x800000 からロード

	ret
