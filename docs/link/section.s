	.section .text, "ax", @progbits
	.byte 0xaa

	.section .rodata, "a", @progbits
	.byte 0x55

	.section .data, "aw", @progbits
	.byte 0xff

	.section .bss, "aw", @nobits
