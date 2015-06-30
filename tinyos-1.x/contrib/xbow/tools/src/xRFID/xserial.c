/**
 * Handles low-level serial communication.
 *
 * @file      xserial.c
 * @author    Martin Turon
 * @version   2004/3/10    mturon      Initial version
 *
 * Copyright (c) 2004 Crossbow Technology, Inc.   All rights reserved.
 * 
 * $Id: xserial.c,v 1.1 2005/03/31 07:51:06 husq Exp $
 */

#include "xsensors.h"

#include <errno.h>
#include <fcntl.h>
#include <termios.h>

#ifdef __CYGWIN__
#include <windows.h>
#include <io.h>
#endif

#ifdef __arm__
#define SERIAL_DEVICE     "/dev/ttyS2"   // default port to use
#else
#define SERIAL_DEVICE     "/dev/ttyS0"   // default port to use
#endif
#define SERIAL_BAUDRATE   B57600         // default baudrate = mica2
#define SERIAL_START_BYTE 0x7e
#define SERIAL_END_BYTE   0x7c

static unsigned    g_baudrate = SERIAL_BAUDRATE;
static const char *g_device   = SERIAL_DEVICE;

/**
 * Opens up a stream to the serial port.
 * 
 * @return    Handle to the serial port as an integer.
 * @author    Martin Turon
 * @version   2004/3/10       mturon      Intial revision
 * @n         2004/3/11       mturon      Fixed cygwin reset problem
 * @n         2004/3/12       mturon      Added improved cygwin fix by dgay
 */
int xserial_port_open() 
{
    /* open serline for read/write */ 
    int serline;
    const char *name = g_device;
    unsigned long baudrate = g_baudrate;
    
    serline = open(name, O_RDWR | O_NOCTTY);
    if (serline == -1) {
        fprintf(stderr, "Failed to open %s\n", name);
        perror("");
        fprintf(stderr, "Verify that user has permission to open device.\n");
        exit(2);
    }
    if (xmain_get_verbose()) printf("%s input stream opened\n", name);

#ifdef __CYGWIN__
    /* Cygwin requires some specific initialization. */
    HANDLE handle = (HANDLE)get_osfhandle(serline);
    DCB dcb;
    if (!(GetCommState(handle, &dcb) &&
	  SetCommState(handle, &dcb))) {
	fprintf(stderr, "serial port initialisation problem\n");
	exit(2);
    }
#endif
    
    /* Serial port setting */
    struct termios newtio;
    bzero(&newtio, sizeof(newtio));
    newtio.c_cflag = CS8 | CLOCAL | CREAD;
    newtio.c_iflag = IGNBRK | IGNPAR;
    cfsetispeed(&newtio, baudrate);
    cfsetospeed(&newtio, baudrate);
    tcflush(serline, TCIFLUSH);
    tcsetattr(serline, TCSANOW, &newtio);

    return serline;
}


/** Writes one XSensorPacket to the serial port. */
int xserial_port_write_packet(int serline, unsigned char *buffer, int len) 
{
    // Use single byte writes for now as they are more stable.

    int err, i=0;
    unsigned char c;

    c=SERIAL_START_BYTE;
    err = write(serline, &c , 1);
//    printf( "%02X ", c);

    c=PROTO_PACKET_NOACK;
    err = write(serline, &c , 1);
//    printf( "%02X ", c);

    for (i=0; i<len; i++)
    {
        err = write(serline, &buffer[i] , 1);
//        printf( "%02X ", buffer[i]);
        if(((i+1)%30)==0) printf("\n");

        if (err < 0) {
            perror("error writing to serial port");
            exit(2);
        }
    }
//    printf ("\n\n");

    c=SERIAL_START_BYTE;
    write(serline, &c , 1);
    return 0;
}


/** Reads one XSensorPacket from the serial port. */
int xserial_port_read_packet(int serline, unsigned char *buffer) 
{
    // Use single byte reads for now as they are more stable.

    unsigned char c;
    int err, i=0;

    buffer[i] = SERIAL_START_BYTE;
    while(1) { 
        err = read(serline, &c, 1);
        
        if (err < 0) {
            perror("error reading from serial port");
            exit(2);
        }
        if (err == 1) {
	    if (++i > 255) return i; 
            buffer[i] = c;
            if (c == SERIAL_START_BYTE) return i;
        }
    }
}


/** Dumps the raw serial traffic.  Warning: Never exits! */
int xserial_port_dump() 
{
    int cnt, serline;
    serline = xserial_port_open();

    while(1) { 
	unsigned char c;
	cnt = read(serline, &c, 1);

	if (cnt < 0) {
            perror("error reading from serial port");
	    exit(2);
	}
        if (cnt == 1) {
            if (c == SERIAL_START_BYTE) printf("\n");
            printf("%02x ", c);
        }
    }
}

unsigned xserial_set_baudrate(unsigned baudrate) {
    switch (baudrate) {
#ifdef B50
	case 50: baudrate = B50; break;
#endif
#ifdef B75
	case 75: baudrate = B75; break;
#endif
#ifdef B110
	case 110: baudrate = B110; break;
#endif
#ifdef B134
	case 134: baudrate = B134; break;
#endif
#ifdef B150
	case 150: baudrate = B150; break;
#endif
#ifdef B200
	case 200: baudrate = B200; break;
#endif
#ifdef B300
	case 300: baudrate = B300; break;
#endif
#ifdef B600
	case 600: baudrate = B600; break;
#endif
#ifdef B1200
	case 1200: baudrate = B1200; break;
#endif
#ifdef B1800
	case 1800: baudrate = B1800; break;
#endif
#ifdef B2400
	case 2400: baudrate = B2400; break;
#endif
#ifdef B4800
	case 4800: baudrate = B4800; break;
#endif
#ifdef B9600
	case 9600: baudrate = B9600; break;
#endif
#ifdef B19200
	case 19200: baudrate = B19200; break;
#endif
#ifdef B38400
	case 38400: baudrate = B38400; break;
#endif
#ifdef B57600
	case 57600: baudrate = B57600; break;
#endif
#ifdef B115200
	case 115200: baudrate = B115200; break;
#endif
#ifdef B230400
	case 230400: baudrate = B230400; break;
#endif
#ifdef B460800
	case 460800: baudrate = B460800; break;
#endif
#ifdef B500000
	case 500000: baudrate = B500000; break;
#endif
#ifdef B576000
	case 576000: baudrate = B576000; break;
#endif
#ifdef B921600
	case 921600: baudrate = B921600; break;
#endif
#ifdef B1000000
	case 1000000: baudrate = B1000000; break;
#endif
#ifdef B1152000
	case 1152000: baudrate = B1152000; break;
#endif
#ifdef B1500000
	case 1500000: baudrate = B1500000; break;
#endif
#ifdef B2000000
	case 2000000: baudrate = B2000000; break;
#endif
#ifdef B2500000
	case 2500000: baudrate = B2500000; break;
#endif
#ifdef B3000000
	case 3000000: baudrate = B3000000; break;
#endif
#ifdef B3500000
	case 3500000: baudrate = B3500000; break;
#endif
#ifdef B4000000
	case 4000000: baudrate = B4000000; break;
#endif
	default:
            baudrate = SERIAL_BAUDRATE;   // Unknown baudrate, using default
    }

    g_baudrate = baudrate;
    return baudrate;
}

unsigned xserial_set_baud(const char *baud) {
    unsigned baudrate = atoi(baud);

    if (strcmp(baud, "mica2") == 0) return xserial_set_baudrate(57600); 
    if (strcmp(baud, "mica2dot") == 0) return xserial_set_baudrate(19200); 

    return xserial_set_baudrate(baudrate);
}

void xserial_set_device(const char *device) {
    g_device = device;
}

