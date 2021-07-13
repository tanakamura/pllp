#include <stdio.h>
#include <string.h>
#include <stdlib.h>

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

/* デバッグ情報のようなもの */
const struct VarDebugInfo dummy_debuginfo[] = {
    {"int_value", TYPE_INT, 0x8000},
    {"str_value", TYPE_CHAR_PTR, 0x8008},
    {NULL}                              /* 終端 */
};

static const struct VarDebugInfo *
extract_var_debug_info(const char *symbol)
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

int
main(int argc, char **argv)
{
    if (argc < 2) {
        printf("usage : %s <symbol>\n", argv[0]);
        return 1;
    }

    const struct VarDebugInfo *info = extract_var_debug_info(argv[1]);

    printf("sym: %s, type:%s, addr=0x%016lx\n",
           info->symbol,
           type_to_str(info->type),
           info->var_addr);

    return 0;
}
