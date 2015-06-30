interface Console {
    command result_t init();
    command void printf0(char *fmt);
    command void printf1(char *fmt, int16_t n);
    command void printf2(char *fmt, int16_t n1, int16_t n2);
    command void newline();
    command void string(char *fmt);
    command void decimal(int32_t n);
    event void input(char *str);
}
