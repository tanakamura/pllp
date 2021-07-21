f:                                    /* fの開始時点では rsp+8 がフレーム開始位置 */
	subq	$24, %rsp             /* この命令の実行後は rsp+32 がフレーム開始位置 */
	leaq	12(%rsp), %rdi
	movl	$1, 12(%rsp)
	call	ret1		      /* call 命令はrspを8減らすのでcallで飛んだ先ではrsp+40がフレーム開始位置、戻ってくるとrsp+32がフレーム開始位置 */
	addq	$24, %rsp             /* この命令の実行後は rsp+8 がフレーム開始位置 */
	ret
