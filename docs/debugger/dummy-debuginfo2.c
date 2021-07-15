#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

enum var_type {
    TYPE_INT,
    TYPE_CHAR_ARRAY
};

static const char *type_to_str(enum var_type t)
{
    switch (t) {
    case TYPE_INT:
        return "int";
    case TYPE_CHAR_ARRAY:
        return "char[]";
    default:
        return "unknown type";
    }
}

struct VarDebugInfo {
    const char *symbol;
    enum var_type type;
    long var_addr;
};

/* デバッグ情報のようなもの */
static const struct VarDebugInfo dummy_debuginfo[] = {
    {"int_value", TYPE_INT, 0x404000},
    {"str_value", TYPE_CHAR_ARRAY, 0x404008},
    {NULL}                              /* 終端 */
};

static const struct VarDebugInfo *
extract_var_debug_info_from_symbol(const char *symbol)
{
    for (int i=0; ; i++) {
        if (dummy_debuginfo[i].symbol == NULL) {
            fprintf(stderr, "cannot find debug info for '%s'.\n", symbol);
            abort();
        }

        if (strcmp(dummy_debuginfo[i].symbol, symbol) == 0) {
            return &dummy_debuginfo[i];
        }
    }
}

static const struct VarDebugInfo *
extract_var_debug_info_from_addr(long addr)
{
    for (int i=0; ; i++) {
        if (dummy_debuginfo[i].symbol == NULL) {
            fprintf(stderr, "cannot find debug info for '0x%016lx'.\n", addr);
            abort();
        }

        if (dummy_debuginfo[i].var_addr == addr) {
            return &dummy_debuginfo[i];
        }
    }
}

int
main(int argc, char **argv)
{
    if (argc < 2) {
        printf("usage : %s <symbol>\n", argv[0]);
        return 1;
    }

    const struct VarDebugInfo *info;

    if (isdigit(argv[1][0])) {
        /* 数字を引数に渡された場合はそれをアドレスとする */
        info = extract_var_debug_info_from_addr(strtol(argv[1], NULL, 0));
    } else {
        /* そうでない場合はシンボル文字列とする */
        info = extract_var_debug_info_from_symbol(argv[1]);
    }

    printf("sym: %s, type:%s, addr=0x%016lx\n",
           info->symbol,
           type_to_str(info->type),
           info->var_addr);

    return 0;
}
