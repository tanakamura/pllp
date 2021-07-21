#include <syscall.h>

/* 最適化で呼び出しが消えないようにGCC 11ではnoipaを付ける */
#define NOINLINE __attribute__((noipa))

NOINLINE static int ret1(void) {
  return 1;
}

int global;

NOINLINE static int f(void) {
  int x0 = ret1();

  /* わかりやすくするため、別の関数を呼んでeaxに入っている戻り値を強制的に別のレジスタに移動させる */
  int x1 = ret1();

  /* わかりやすくするため、命令を一個入れる */
  global++;
  return x0 + x1;
}

int
_start()
{
    int ret = f();
    __asm__ __volatile__("syscall"::"a"(60),"D"(ret));

}
