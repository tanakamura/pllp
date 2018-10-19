	.globl main

main:
	mov	$0x11, %al    	# 8bit 命令は別のオペコードが割り当てられている
	mov	$0x1122, %ax	# 16bit 命令は0x66が付く
	mov	$0x11223344, %eax # 32bit 命令はプレフィクスが付かない
	mov	$0x1122334455667788, %rax # 64bit 命令は、REXプレフィクスが付く。この場合は0x48

	ret
