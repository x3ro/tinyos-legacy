/*
 * re-write of "listen.c" to be a bit more efficient and robust
 *
 * Kevin Fall, Intel research
 * May 2002
 */

/*
 * IMPORTANT:  READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.
 * By downloading, copying, installing or using the software you agree to this
 * license.  If you do not agree to this license, do not download, install,
 * copy or use the software.
 * 
 * Intel Open Source License 
 * 
 * Copyright (c) 1996-2002 Intel Corporation. All rights reserved. 
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met: 
 * 
 * 	Redistributions of source code must retain the above copyright notice,
 * 	this list of conditions and the following disclaimer. 
 * 
 * 	Redistributions in binary form must reproduce the above copyright
 * 	notice, this list of conditions and the following disclaimer in the
 * 	documentation and/or other materials provided with the distribution. 
 * 
 * 	Neither the name of the Intel Corporation nor the names of its
 * 	contributors may be used to endorse or promote products derived from
 * 	this software without specific prior written permission.
 *  
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS IS'' * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE INTEL OR ITS  CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#include <sys/types.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/ioctl.h>
#include <fcntl.h>
#include <termios.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>

#define PACKET_LENGTH 36 /*3 header bytes, 31 body bytes, 2 crc bytes */
#define BAUDRATE B19200 /* the baudrate that the device is talking */
#define SERIAL_DEVICE "/dev/ttyS0" /* tty device */
#define	RWAIT	1	/* in deci-second time units for read to go */
#define PACKET_MAGIC 0x7e /* sync byte from mote b/s in data stream */
			  /* happens to be the PPP sync byte too */

int open_input(char *);
int read_packet(int, unsigned char *, int);
void restore_tty();
void print_packet(unsigned char *, int);

struct termios orig_termios;
int ttyfd = -1;

int main(int argc, char *argv[])
{
   static unsigned char buf[BUFSIZ];
   char *ourtty = NULL;

   if (argc != 2) {
   	fprintf(stderr, "No input device specified, assuming %s\n",
		SERIAL_DEVICE);
	argv[1] = SERIAL_DEVICE;
   } else if (argc > 3) {
   	fprintf(stderr, "Too many args: Usage: %s <ttydevice>\n",
		argv[0]);
	exit(1);
   }
   ourtty = ttyname(0);
   if (ourtty && (strcmp(ourtty, argv[1]) == 0)) {
   	int c;
   	fprintf(stderr, "Warning: attaching to controlling terminal %s.  Continue (y/[n])? ", ourtty);
	fflush(stderr);
	if ((c = getchar()) != 'y' && (c != 'Y')) {
		fprintf(stderr, "Aborted.\n");
		exit(1);
	}
   }

   if ((ttyfd = open_input(argv[1])) < 0)
   	exit(1);
   (void)signal(SIGINT, restore_tty);	
   while(1) {
   	int n = read_packet(ttyfd, buf, sizeof(buf));
	if (n >= 0)
		print_packet(buf, n);
	else
		break;
   }
   (void)close(ttyfd);
   exit(0);
}

void
restore_tty()
{
	(void)tcsetattr(ttyfd, TCSANOW, &orig_termios);
	(void)close(ttyfd);
	exit(0);
}

int
open_input(char *dev)
{
    /* open input_stream for read/write */ 
    static struct termios newtio;
    int fd =  open(dev, O_RDONLY|O_NOCTTY|O_EXCL);
    if (fd < 0) {
	perror("open tty device");
	fprintf(stderr, "Make sure you have permission to open %s.\n",
		dev);
	return (-1);
    }
    printf("input_stream %s opens ok\n", dev);

    if (tcgetattr(fd, &orig_termios) < 0)
    	perror("tcgetattr");

    /* Serial port setting */
    newtio.c_cflag = BAUDRATE | CS8 | CLOCAL | CREAD;
    newtio.c_iflag = IGNPAR | ICRNL;
    newtio.c_cc[VMIN] = PACKET_LENGTH;
    newtio.c_cc[VTIME] = RWAIT;

    /* Raw output_file */
    newtio.c_oflag = 0;
    if (tcflush(fd , TCIFLUSH) < 0)
    	perror("tcflush");

    if (tcsetattr(fd, TCSANOW, &newtio) < 0) {
    	perror("tcsetattr");
    	return (-1);
    }	
    return (fd);
}

void
print_packet(unsigned char *buf, int n)
{
	int i;
	printf("data[%d bytes]:\n\t", n);
	for(i = 0; i < n; i ++){
		printf("%02x ", buf[i] & 0xff);
		if ((i & 0x0f) == 0x0f)
			printf("\n\t");
	}
	printf("\n");
	fflush(stdout);
} 


int
read_packet(int fd, unsigned char *buf, int buflen)
{
	int n;
	int cnt = 0, complete = 0;
	unsigned char *p = NULL;

	if (PACKET_LENGTH > buflen) {
		fprintf(stderr, "mote_input: problem: pkt size %d is too large for buffer of size %d bytes\n",
			PACKET_LENGTH, buflen);
		return -1;
	}

	/*
	 * read through input making sure to look for 1st framing character
	 * and that the length is sufficient
	 */

	while ((n = read(fd, buf + cnt, buflen - cnt)) > 0) {
		if (!p && ((p = memchr(buf + cnt, PACKET_MAGIC, n)) == NULL)) {
			/* didn't find framing byte anywhere here */
			cnt = 0;
			continue;
		}
		cnt += n;
		if (((buf + cnt) - p) >= PACKET_LENGTH) {
			complete = 1;
			break;
		}
	}
	if (n < 0)
		perror("mote_input: read");
	else if (n == 0)
		fprintf(stderr, "mote_input: nobody home\n");

	if (!complete) {
		fprintf(stderr, "mote_input: not complete: cnt:%d, (p-buf):%d, fd:%d\n",
			cnt, (p-buf), fd);
		return (-1);
	}
	return (cnt - (p - buf));
}
