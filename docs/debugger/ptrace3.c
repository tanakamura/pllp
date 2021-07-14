#include <stdio.h>
#include <sys/ptrace.h>
#include <sys/wait.h>
#include <sys/user.h>
#include <stdint.h>
#include <unistd.h>
#include <signal.h>

int
main(int argc, char **argv)
{
    int pid;
    if ( (pid = fork()) == 0) {
        /* 子プロセス(tracee) */
        while (1)
          ;
    } else {
        /* 親プロセス(tracer) */
        int st;

        usleep(1000);
        ptrace(PTRACE_ATTACH, pid, 0, 0); /* 子プロセスを監視対象(tracee)にする */
        waitpid(pid, &st, 0);  /* traceeが停止するまで待機 */

        struct user_regs_struct regs;

        ptrace(PTRACE_GETREGS, pid, 0, &regs);  /* traceeのレジスタの値を取得 */
        printf("rip=%016llx, main=%016llx, delta=%llx\n", (long long)regs.rip, (long long)main, (long long)regs.rip - (long long)main);

        ptrace(PTRACE_DETACH, pid, 0, 0); /* traceeを監視対象から外す */

        kill(pid, SIGKILL);
        waitpid(pid, &st, 0);
    }

    return 0;
}
