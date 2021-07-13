#include <stdio.h>
#include <sys/ptrace.h>
#include <sys/wait.h>
#include <stdint.h>
#include <unistd.h>
#include <signal.h>

int
main(int argc, char **argv)
{
    uint64_t x;
    int pid;
    if ( (pid = fork()) == 0) {
        /* 子プロセス */
        x = 0xaa55aa55;

        while (1) {
            sleep(10);
        }
    } else {
        int st;

        /* 親プロセス */
        x = 2000;

        usleep(1000);

        ptrace(PTRACE_ATTACH, pid, 0, 0); /* 子プロセスを監視対象にする */
        waitpid(pid, &st, 0);                     /* 子プロセスが停止するまで待機 */

        x = ptrace(PTRACE_PEEKDATA, pid, &x, 0);
        printf("%x\n", (int)x);

        kill(pid, SIGKILL);
    }

    return 0;
}
