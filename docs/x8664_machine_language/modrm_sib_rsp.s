	.globl	main
main:
	## ModR/M=0b0001_0100 : mod=0b00 (dispなし), reg=0b010(edx), r/m=0b100(SIB)
	## SIB   =0b0010_0100 : scale=0b00(x1), index=0b100(なし), base=0b100(rsp)
	mov	(%rsp), %edx
	ret
