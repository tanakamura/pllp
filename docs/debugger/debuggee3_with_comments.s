f:
	pushq	%rbx			/* まだローカル変数はない */
	call	ret1 			/* この命令実行後に、戻り値がeaxに入っている */
	movl	%eax, %ebx		/* この命令実行後にx0 はebxレジスタに乗る */
	call	ret1			/* この命令実行後に、戻り値がeaxに入っている、これがそのままx1になる。x0はebxレジスタにある */	
	addl	$1, global(%rip)	/* x0はebxレジスタにある。x1はeaxレジスタにある */
	addl	%ebx, %eax		/* 戻り値がeaxに入る、x1はeaxレジスタが書きかえられるので消滅する。x0はebxレジスタにある */
	popq	%rbx			/* ebxを復元、x0はebxレジスタが書きかえられるので消滅する */
	ret				/* ローカル変数はない */
