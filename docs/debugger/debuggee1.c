int int_value = 1234;
char str_value[] = "Hello World";

int _start() {
  int_value = 9999;
  str_value[0] = '@';

  asm volatile (" "  ::: "memory");  /* メモリへ必ず書き込むようにする */

  while (1)
    ;
}
