int a;
int _start() {
    a++;

    *(int*)0 = 0;                       /* アドレス0にアクセス、エラーを起こして停止させる */

    return 10;
}
