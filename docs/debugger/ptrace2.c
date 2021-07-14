#include <stdio.h>
#include <sys/ptrace.h>
#include <sys/wait.h>
#include <stdint.h>
#include <unistd.h>
#include <signal.h>

int
main(int argc, char **argv)
{
    volatile uint64_t x;  /* 他のプログラムから読み書きする変数はvolatileにする */
    int pid;
    if ( (pid = fork()) == 0) {
        /* 子プロセス(tracee) */
        x = 0;
        while (x==0)  /* tracerが書きかえてくれるまで待つ */
            ;
        printf("%x\n", (int)x);
    } else {
        /* 親プロセス(tracer) */
        int st;

        usleep(1000);
        ptrace(PTRACE_ATTACH, pid, 0, 0); /* 子プロセスを監視対象(tracee)にする */
        waitpid(pid, &st, 0);  /* traceeが停止するまで待機 */

        uint64_t newdata = 0x88888888;

        ptrace(PTRACE_POKEDATA, pid, &x, (void*)(uintptr_t)newdata); /* traceeのメモリへ書き込み */
        ptrace(PTRACE_CONT, pid, 0, 0);  /* 停止したtraceeを再開 */
        ptrace(PTRACE_DETACH, pid, 0, 0); /* traceeを監視対象から外す */

        waitpid(pid, &st, 0);  /* 子プロセスの終了待ち */
    }

    return 0;
}
