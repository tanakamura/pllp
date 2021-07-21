#include <syscall.h>

/* 最適化で呼び出しが消えないようにGCC 11ではnoipaを付ける */
#define NOINLINE __attribute__((noipa))

NOINLINE static int ret1(int *p) {
  return *p;
}

NOINLINE static int f(void) {
  int x0 = 1;
  return ret1(&x0);
}

int
_start()
{
    int ret = f();
    __asm__ __volatile__("syscall"::"a"(60),"D"(ret));

}
