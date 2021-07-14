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
        x = 0xaa55aa55;

        while (1) {
            sleep(10);
        }
    } else {
        /* 親プロセス(tracer) */
        int st;

        usleep(1000);

        ptrace(PTRACE_ATTACH, pid, 0, 0); /* 子プロセスを監視対象(tracee)にする */
        waitpid(pid, &st, 0);  /* traceeが停止するまで待機 */

        x = ptrace(PTRACE_PEEKDATA, pid, &x, 0);  /* traceeのメモリから値を取得 */
        printf("%x\n", (int)x);

        ptrace(PTRACE_DETACH, pid, 0, 0); /* traceeを監視対象から外す */

        kill(pid, SIGKILL);  /* 子プロセスの終了 */
        waitpid(pid, &st, 0);
    }

    return 0;
}
