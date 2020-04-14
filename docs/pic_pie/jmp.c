int main(int argc, char **argv)
{
    volatile int a = 0;
    if (argc == 1) {
        goto label;
    }

    a++;

label:
    return 0;
}