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
        /* 子プロセス */
        while (1)
          ;
    } else {
        int st;

        /* 親プロセス */

        sleep(1);
        ptrace(PTRACE_ATTACH, pid, 0, 0); /* 子プロセスを監視対象にする */
        waitpid(pid, &st, 0);  /* 子プロセスが停止するまで待機 */

        struct user_regs_struct regs;

        ptrace(PTRACE_GETREGS, pid, 0, &regs);
        printf("rip=%016llx, main=%016llx, delta=%llx\n", (long long)regs.rip, (long long)main, (long long)regs.rip - (long long)main);

        kill(pid, SIGKILL);
    }

    return 0;
}
