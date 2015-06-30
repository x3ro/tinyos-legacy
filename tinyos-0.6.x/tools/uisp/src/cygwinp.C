
#if defined(__CYGWIN__)

#include <termios.h>
#include <w32api/windows.h>
#include "cygwinp.h"
#include "DAPA.h"

unsigned char inb(unsigned short port)
{
    unsigned char t;
    asm volatile ("in %1, %0"
		  : "=a" (t)
		  : "d" (port));
    return t;
}

void outb(unsigned char value, unsigned short port)
{
    asm volatile ("out %1, %0"
		  :
		  : "d" (port), "a" (value) );
}

int ioperm(unsigned short port, int num, int enable)
{
    if (enable) {
	// Only try to use directio under Windows NT/2000.
	OSVERSIONINFO ver_info;
	memset(&ver_info, 0, sizeof(ver_info));
	ver_info.dwOSVersionInfoSize = sizeof(ver_info);
	if (! GetVersionEx(&ver_info))
	    return -1;
	else if (ver_info.dwPlatformId == VER_PLATFORM_WIN32_NT) {
	    HANDLE h =
		CreateFile("\\\\.\\giveio",
			   GENERIC_READ,
			   0,
			   NULL,
			   OPEN_EXISTING,
			   FILE_ATTRIBUTE_NORMAL,
			   NULL);
	    if (h == INVALID_HANDLE_VALUE)
		return -1;
	    CloseHandle(h);
	}
    }
    return 0;
}

bool cygwinp_delay_usec(long t)
{
    static bool perf_counter_checked = false;
    static bool use_perf_counter = false;
    static LARGE_INTEGER freq = 0;

    if (! perf_counter_checked) {
	if (QueryPerformanceFrequency(&freq))
	    use_perf_counter = true;
	perf_counter_checked = true;
    }

    if (! use_perf_counter)
	return false;
    else {
	LARGE_INTEGER now;
	LARGE_INTEGER finish;
	QueryPerformanceCounter(&now);
	finish.QuadPart = now.QuadPart + (t * freq.QuadPart) / 1000000;
	do {
	    QueryPerformanceCounter(&now);
	} while (now.QuadPart < finish.QuadPart);
	return true;
    }
}


int cfmakeraw(struct termios *termios_p)
{
    termios_p->c_iflag &=
	~(IGNBRK|BRKINT|PARMRK|ISTRIP |INLCR|IGNCR|ICRNL|IXON);
    termios_p->c_oflag &= ~OPOST;
    termios_p->c_lflag &= ~(ECHO|ECHONL|ICANON|ISIG|IEXTEN);
    termios_p->c_cflag &= ~(CSIZE|PARENB);
    termios_p->c_cflag |= CS8;
    return 0;
}

#endif
