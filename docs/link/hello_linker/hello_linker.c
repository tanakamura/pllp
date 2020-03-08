#include <stdio.h>
#include <elf.h>
#include <string.h>
#include <stdlib.h>
#include <stdint.h>

#define MAX_SYMBOL_NUM 1024
#define MAX_RELOC_NUM 1024
#define MAX_SYMBOL_LEN 63
#define MAX_SEGMENT_SIZE 4096
#define MAX_SECTION_SIZE 4096
#define MAX_FILE_SIZE (4096*4)

struct symbol {                 /* 定義済みシンボル */
    char sym[MAX_SYMBOL_LEN + 1]; /* シンボル文字列 */
    int section;                /* 所属するセクション */
    uintptr_t offset;           /* セクション中のオフセット */
    uintptr_t addr;             /* リンク後のアドレス */
};

struct reloc {                  /* リンク後に解決すべきリロケーション */
    char sym[MAX_SYMBOL_LEN + 1]; /* シンボル文字列 */
    int reloc_type;             /* リロケーションの方法 */
    int section;                /* 所属するセクション */
    uintptr_t offset;           /* セクション中のオフセット */
};

struct resolved_reloc {         /* 名前解決済みリロケーション */
    int reloc_type;             /* リロケーションの方法 */
    int reloc_section;          /* このリロケーションのセクション */
    uintptr_t reloc_offset; /* このリロケーションのセクション内のオフセット */

    int sym_section;      /* 参照先のシンボルのセクション */
    uintptr_t sym_offset; /* 参照先のシンボルのセクション内のオフセット */
};

struct section {
    int align;
    int cur_size;               /* 現在出力したサイズ */
    char buffer[MAX_SECTION_SIZE]; /* 出力したデータ */

    int cur_file_offset;        /* 今の入力ファイルでのセクションのオフセット */
};

struct segment {
    int cur_alloc_size;         /* bssを含む出力したサイズ */
    int cur_contents_size;      /* bssを含まない出力したサイズ */
    char buffer[MAX_SEGMENT_SIZE]; /* 出力したデータ */
};

#define TEXT_SECTION 0
#define DATA_SECTION 1
#define RODATA_SECTION 2
#define BSS_SECTION 3

static int
section_name_to_index(const char *section_name) {
    if (strcmp(section_name, ".text") == 0) {
        return TEXT_SECTION;
    }
    if (strcmp(section_name, ".data") == 0) {
        return DATA_SECTION;
    }
    if (strcmp(section_name, ".rodata") == 0) {
        return RODATA_SECTION;
    }
    if (strcmp(section_name, ".bss") == 0) {
        return BSS_SECTION;
    }

    return -1;
}

#define EXEC_SEGMENT 0
#define RO_SEGMENT 1
#define RW_SEGMENT 2

struct symtab {
    int num_symbol;
    struct symbol symbols[MAX_SYMBOL_NUM];
};

struct linker {
    struct symtab local,global;

    int num_reloc;
    struct reloc relocs[MAX_RELOC_NUM];

    struct section sections[4];
    struct segment segments[3];

    char file_buffer[MAX_FILE_SIZE];
};

static void
init_linker(struct linker *l) {
    l->local.num_symbol = 0;
    l->global.num_symbol = 0;
    l->num_reloc = 0;
    for (int i=0; i<4; i++) {
        l->sections[i].cur_size = 0;
        l->sections[i].align = 0;
    }

    for (int i=0; i<3; i++) {
        l->segments[i].cur_alloc_size = 0;
        l->segments[i].cur_contents_size = 0;
    }
}

static Elf64_Shdr *
get_shdr(Elf64_Ehdr *ehdr, int index)
{
    char *elf_bin = (char*)ehdr;

    /* セクションヘッダの先頭はファイルの先頭から EHDR の e_shoff 足したところにある */
    char *shent = elf_bin + ehdr->e_shoff;

    /* N番目のセクションヘッダはセクションヘッダの先頭から e_shentsize * N したところにある */
    return (Elf64_Shdr*)(shent + ehdr->e_shentsize * index);
}
         
static char *
get_section_contents(Elf64_Ehdr *ehdr,
                     Elf64_Shdr *shdr)
{
    /* 各セクションのデータはファイルの先頭から Shdr の sh_offset バイト目のところにある */
    return ((char*)ehdr) + shdr->sh_offset;
}

static void
add_elf(struct linker *l,
        const char *path)
{
    l->local.num_symbol = 0;    /* ローカルシンボルテーブル初期化 */

    FILE *fp = fopen(path, "rb");
    if (fp == 0) {
        perror(path);
        exit(1);
    }

    size_t rdsz = fread(l->file_buffer, 1, MAX_FILE_SIZE, fp);
    fclose(fp);

    if (rdsz == MAX_FILE_SIZE) {
        printf("%s : ファイルサイズが多きすぎます\n", path);
        exit(1);
    }

    Elf64_Ehdr *ehdr = (Elf64_Ehdr*)l->file_buffer;

    /* ELF ファイルの先頭4byte は 0x7f, 'E', 'L', 'F' */
    if ((ehdr->e_ident[0] != 0x7f) ||
        (ehdr->e_ident[1] != 'E') ||
        (ehdr->e_ident[2] != 'L') ||
        (ehdr->e_ident[3] != 'F'))
    {
        printf("%s : ELFファイルではないです\n", path);
        exit(1);
    }

    /* リロケータブルなファイルだけ扱う(実行ファイルは入力に使えない) */
    if (ehdr->e_type != ET_REL) {
        printf("%s : 無効なファイルタイプです (リロケータブルなオブジェクトのみ使えます)\n", path);
        exit(1);
    }


    /* x86_64のみサポート */
    if (ehdr->e_machine != EM_X86_64) {
        printf("%s : x86_64 用のオブジェクトではありません\n", path);
        exit(1);
    }

    /* ラベル等の文字列データは e_shstrndx 番目のセクションに格納されている */
    Elf64_Shdr *shstrtab = get_shdr(ehdr, ehdr->e_shstrndx);
    char *shstrtab_data = get_section_contents(ehdr, shstrtab);

    char *strtab_data = 0;


    for (int si=0; si<ehdr->e_shnum; si++) {
        Elf64_Shdr *shdr = get_shdr(ehdr, si);
        if (shdr->sh_type == SHT_PROGBITS ||
            shdr->sh_type == SHT_NOBITS
            ) /* リンクすべきデータはSHT_PROGBITS か SHT_NOBITSのセクションに含まれている */
        {
            /* セクション名はstrtabセクションのsh_nameバイト目に含まれている */
            char *section_name = shstrtab_data + shdr->sh_name;
            int section = section_name_to_index(section_name);

            if (section == -1) {
                printf("%s : サポートされないセクション名(%s)が含まれています\n",
                       path, section_name);
            }

            size_t cur = l->sections[section].cur_size;

            /* 配置アドレスをアラインする */
            cur += shdr->sh_addralign-1;
            cur /= shdr->sh_addralign;
            cur *= shdr->sh_addralign;

            /* リンク後にアラインされるようにアラインの最大値を保存しておく */
            if (shdr->sh_addralign > l->sections[section].align) {
                l->sections[section].align = shdr->sh_addralign;
            }

            /* 現在の先頭位置を保存 */
            l->sections[section].cur_file_offset = cur;

            if ((cur + shdr->sh_size) > MAX_SEGMENT_SIZE) {
                printf("%s : %sセクションがあふれました\n", path, section_name);
            }

            if (shdr->sh_type == SHT_PROGBITS) {
                /* PROGBITSの場合はその内容をコピー (NOBITSの場合はコピーしないでオフセットだけ増やす) */
                char *dst = &l->sections[section].buffer[cur];
                char *src = get_section_contents(ehdr, shdr);
                memcpy(dst, src, shdr->sh_size);
            }

            l->sections[section].cur_size = cur + shdr->sh_size;
        } else if (shdr->sh_type == SHT_STRTAB) {
            char *section_name = shstrtab_data + shdr->sh_name;
            if (strcmp(section_name, ".strtab") == 0) {
                strtab_data = get_section_contents(ehdr, shdr);
                break;
            }
        }
    }
    
    if (strtab_data == 0) {
        printf("%s : .strtab セクションが見つかりません\n", path);
        exit(1);
    }

    char *syms_data = 0;

    for (int si=0; si<ehdr->e_shnum; si++) {
        Elf64_Shdr *shdr = get_shdr(ehdr, si);

        if (shdr->sh_type == SHT_SYMTAB) {
            /* シンボルが入っている */
            syms_data = get_section_contents(ehdr, shdr);

            /* 含まれるシンボルの数はセクションのサイズをエントリのサイズで割ったもの */
            int num_symbol = shdr->sh_size / shdr->sh_entsize;

            for (int symi=0; symi<num_symbol; symi++) {
                Elf64_Sym *sym = (Elf64_Sym*)(syms_data + symi * shdr->sh_entsize);

                if ((sym->st_shndx != SHN_UNDEF) &&
                    (sym->st_shndx < SHN_LORESERVE) && 
                    (sym->st_name != STN_UNDEF) )
                {
                    /* SHN_UNDEF が未定義シンボル
                     * SHN_LORESERVE以上は他の目的で予約済み 
                     * それ以外が定義済みシンボル
                     *
                     * STN_UNDEFは無視でよい
                     */

                    char *name = strtab_data + sym->st_name;

                    struct symtab *symtab = &l->global;
                    int bind = ELF64_ST_BIND(sym->st_info);
                    //int type = ELF64_ST_TYPE(sym->st_info);

                    switch (bind) {
                    case STB_LOCAL:
                        /* ファイル内で定義されたシンボル */
                        symtab = &l->local;
                        break;

                    case STB_GLOBAL:
                        /* グローバルに定義されたシンボル */
                        symtab = &l->global;
                        break;

                    default:
                        printf("%s : サポートされないシンボルです\n", path);
                        exit(1);
                    }

                    if (symtab->num_symbol >= MAX_SYMBOL_NUM) {
                        printf("%s : シンボルテーブルがあふれました\n", path);
                        exit(1);
                    }

                    /* 定義済みシンボルを登録する */
                    struct symbol *dst = &symtab->symbols[symtab->num_symbol];
                    symtab->num_symbol++;

                    if (strlen(name) >= MAX_SYMBOL_LEN) {
                        printf("%s : %s シンボルが長すぎます\n", path, name);
                        exit(1);
                    }

                    Elf64_Shdr *sym_section = get_shdr(ehdr, sym->st_shndx);
                    char *sym_section_name = shstrtab_data + sym_section->sh_name;
                    int section = section_name_to_index(sym_section_name);

                    strcpy(dst->sym, name);
                    dst->section = section;
                    dst->offset = sym->st_value + l->sections[section].cur_file_offset;
                }
            }
        }
    }

    for (int si=0; si<ehdr->e_shnum; si++) {
        /* ローカルなリロケーションを解決する 
         * 解決できないリロケーションは保存してあとまわしにする
         */

        Elf64_Shdr *shdr = get_shdr(ehdr, si);
        if (shdr->sh_type == SHT_REL) {
            /* オフセット加算無しリロケーション */
        } else if (shdr->sh_type == SHT_RELA) {
            /* オフセット加算付きリロケーション */
            
        }
    }

    if (syms_data == 0) {
        printf("%s : シンボルテーブルが見つかりません\n", path);
        exit(1);
    }
}

static void
usage()
{
    puts("hello_linker [-o output_file] input_file input_file ..");
}

int
main(int argc, char **argv)
{
    const char *outfile = "a.out";
    struct linker l;

    init_linker(&l);

    int opt = 1;
    while (opt < argc) {
        if (argv[opt][0] == '-') {
            switch (argv[opt][1]) {
            case 'o':
                if (opt == argc-1) {
                    usage();
                    return 1;
                }
                outfile = argv[opt+1];
                opt+=2;
                break;

            default:
                usage();
                return 1;
            }
        } else {
            add_elf(&l, argv[opt]);

            opt ++;
        }
    }
}