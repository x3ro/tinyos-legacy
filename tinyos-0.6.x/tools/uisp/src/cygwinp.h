
#include <sys/time.h>

unsigned char inb(unsigned short port);
void outb(unsigned char value, unsigned short port);
int ioperm(unsigned short port, int num, int enable);
int cfmakeraw(struct termios *termios_p);
bool cygwinp_delay_usec(long t);
