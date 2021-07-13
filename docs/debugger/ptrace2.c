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
        sleep(2);
        printf("%x\n", (int)x);
    } else {
        int st;

        /* 親プロセス */

        usleep(1000);
        ptrace(PTRACE_ATTACH, pid, 0, 0); /* 子プロセスを監視対象にする */
        waitpid(pid, &st, 0);                     /* 子プロセスが停止するまで待機 */

        uint64_t newdata = 0x88888888;

        ptrace(PTRACE_POKEDATA, pid, &x, (void*)(uintptr_t)newdata);
        ptrace(PTRACE_DETACH, pid, 0, 0);  /* 子プロセスを再開 */

        wait(&st);
    }

    return 0;
}
