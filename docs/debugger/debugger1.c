/* gdb の print のような機能を実現するプログラム */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/ptrace.h>
#include <sys/wait.h>
#include <stdint.h>

enum var_type {
    TYPE_INT,
    TYPE_CHAR_PTR
};

const char *type_to_str(enum var_type t)
{
    switch (t) {
    case TYPE_INT:
        return "int";
    case TYPE_CHAR_PTR:
        return "char*";
    default:
        return "unknown type";
    }
}

struct VarDebugInfo {
    const char *symbol;
    enum var_type type;
    long var_addr;
};

/* debugee1.c のデバッグ情報 */
const struct VarDebugInfo debuginfo_for_debugee1[] = {
    /* var_addr には readelf -s で取得したアドレスを入れる */
    {"int_value", TYPE_INT, 0x404000},
    {"str_value", TYPE_CHAR_PTR, 0x404008},
    {NULL}                              /* 終端 */
};
static const struct VarDebugInfo *
extract_var_debug_info(const char *symbol)
{
    for (int i=0; ; i++) {
        if (debuginfo_for_debugee1[i].symbol == NULL) {
            fprintf(stderr, "cannot find debug info for '%s'.\n", symbol);
            abort();
        }

        if (strcmp(debuginfo_for_debugee1[i].symbol, symbol) == 0) {
            return &debuginfo_for_debugee1[i];
        }
    }
}

static void
print_var_info(int pid, const struct VarDebugInfo *info)
{
    int v;
    long ptr;
    char buffer[1024];

    switch (info->type) {
    case TYPE_INT:
        v = ptrace(PTRACE_PEEKDATA, pid, (void*)info->var_addr, 0);
        printf("%s:%d, addr=%lx\n", info->symbol, v, info->var_addr);
        break;

    case TYPE_CHAR_PTR:
        ptr = ptrace(PTRACE_PEEKDATA, pid, (void*)(info->var_addr), 0);
        for (int i=0; ; i++) {
            uint8_t v8 = ptrace(PTRACE_PEEKDATA, pid, (void*)(ptr+i), 0);
            buffer[i] = v8;
            if (v8 == 0) {
                break;
            }
        }
        printf("%s:%s, var_addr=%lx, value_addr=%lx\n", info->symbol, buffer, info->var_addr, ptr);
        break;

    default:
        puts("xx");
    }
}

int
main(int argc, char **argv)
{
    if (argc < 2) {
        printf("usage : %s <symbol>\n", argv[0]);
        return 1;
    }

    int r = access("./debugee1", X_OK);
    if (r < 0) {
        fprintf(stderr, "cannot find program `debugee1` (please compile debugee1.c)\n");
        return 1;
    }

    int pid;
    if ( (pid=fork()) == 0) {
        char *argv[2] = {"./debugee1",NULL};
        execve("./debugee1", argv, NULL);
    } else {
        int st;
        usleep(1000);
        int r = ptrace(PTRACE_ATTACH, pid);
        if (r < 0) {
            perror("ptrace");
            return 1;
        }
        waitpid(pid, &st, 0);

        const struct VarDebugInfo *info = extract_var_debug_info(argv[1]);

        print_var_info(pid, info);

        kill(pid, SIGKILL);
    }
}
