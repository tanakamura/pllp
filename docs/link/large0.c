#include <stdio.h>
extern int a[];
extern int b[];

int main()
{
    printf("%d %d\n", a[0], b[0]);
}