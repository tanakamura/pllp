	.globl	main
main:
	## ModR/M=0b0001_0100 : mod=0b00 (dispなし), reg=0b010(edx), r/m=0b100(SIB)
	## SIB   =0b0000_1000 : scale=0b00(x1), index=0b001(rcx), base=0b000(rax)
	mov	(%rax,%rcx), %edx

	## ModR/M=0b0001_0100 : mod=0b00 (dispなし), reg=0b010(edx), r/m=0b100(SIB)
	## SIB   =0b0100_1000 : scale=0b01(x2), index=0b001(rcx), base=0b000(rax)
	mov	(%rax,%rcx,2), %edx

	## ModR/M=0b0101_0100 : mod=0b01 (8bit disp), reg=0b010(edx), r/m=0b100(SIB)
	## SIB   =0b0000_1000 : scale=0b00(x1), index=0b001(rcx), base=0b000(rax)
	## disp  =0x1
	mov	1(%rax,%rcx), %edx

	ret
