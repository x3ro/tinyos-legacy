/*                                                                      tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *
 */
/*                                                                      tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */
/*                                                                      tab:4
 * Copyright (c) 2003 Intel Corporation
 * All rights reserved Contributions to the above software program by Intel
 * Corporation is program is licensed subject to the BSD License, available at
 * http://www.opensource.org/licenses/bsd-license.html
 *
 */
/*
 * Authors:	Mark Yarvis
 *
 */

#include <stdio.h>

#include <errno.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>

#include <sys/types.h>
#include <fcntl.h>

#include <netdb.h>
#include <sys/socket.h>
#include <netinet/in.h>

#include <termios.h>

#include <signal.h>

#ifndef VERSION
#define VERSION "unknown"
#endif

#define DEFAULT_COM "COM1"
#define DEFAULT_SERVER_PORT 9001

#define PERSISTENCE_CHECK_PERIOD 5000

#define MAX_IO_STREAMS 100

// The max number of characters that could be in either a raw or ASCII message
#define MAX_MESSAGE_LEN 200

#define BUFFER_SIZE (MAX_MESSAGE_LEN*3)

char* comPorts[][2] = { { "COM1", "/dev/ttyS0"}, 
                        { "COM2", "/dev/ttyS1"},
                        { "COM3", "/dev/ttyS2"},
                        { "COM4", "/dev/ttyS3"},
                        { "COM5", "/dev/ttyS4"},
                        { "COM6", "/dev/ttyS5"},
                        { "COM7", "/dev/ttyS6"},
                        { 0, 0}
                      };

#define MICA 1
#define MICA2 2
#define IMOTE 3
#define MAX_MOTE_TYPE 3

#define BAUD_RATE 0
#define USE_PREAMBLE 1
int mote_configs[][2] = { { 0, 0 },       // NOT USED
                          { B19200, 0 },  // MICA
                          { B57600, 1 },  // MICA2
                          { B115200, 0 }  // Imote
                   };

#define SF_VERSION_STRING "T "

char uart_frame_vals[3] = {0x97, 0x53, 0x71};
char uart_preamble_vals[5] = {0xFF, 0x00, 0xFF, 0x00, 0xFF};

// types
#define CLIENT_SOCKET 1
#define SERVER_SOCKET 2
#define SERIAL_PORT   3

// formats
#define ASCII_FORMAT  1
#define RAW_FORMAT    2
#define FRAMED_FORMAT 3
   // for communication with serial forwarder
#define SF_FORMAT     4 

typedef struct {
   int fd;
   char name[100];
   char buf[BUFFER_SIZE];  // input buffer
   int bufLen; // number of bytes in buffer
   char type;
//   char useRawIO;
//   char useFramedIO;   // only valid for Raw IO
   char format;   // only valid for Raw IO
   char writePreamble;
   char bePersistent;
   struct termios origtio;  // original serial port settings to restore
} ioStream;

ioStream streams[MAX_IO_STREAMS];
int numStreams = 0;

char usePersistentSockets = 1;

int packetLen = 0;  // use for raw unframed communication only!

void printUsage(char *progName) {
   printf("Uage: %s [-1 | -2] [ <com spec> ... ] [ -r<len> <com spec>] [ -sf <host>:<port>]\n", progName);
   printf("    Where <com spec> is one of\n");
   printf("        port        - to create a server socket\n");
   printf("        host:port   - to connect to a server\n");
   printf("        COMn        - to connect to a comm port\n");
   printf("    And additional options are\n");
   printf("        -r<len>        - opens any subsequent comm ports for unframed\n");
   printf("                         and non-ascii communication with packets of\n");
   printf("                         the specified length\n");
   printf("        -sf        - opens any subsequent sockets for communication \n");
   printf("                     using the serial forwarder protocol\n");
   printf("        -1              - opens any subsequent comm ports with a baud\n");
   printf("                      rate for RENE or MICA motes\n");
   printf("        -2              - opens any subsequent comm ports with a baud\n");
   printf("                      rate for MICA2 motes\n");
}

long currentTimeMillis() {
   struct timeval tv;

   gettimeofday(&tv, 0);

   return (tv.tv_sec*1000) + (tv.tv_usec / 1000);
}

void restoreSerialSettings(ioStream *s) {
   if (s->type == SERIAL_PORT) {
      printf("Restoring serial settings on %s\n", s->name);
      tcsetattr(s->fd,TCSANOW,&(s->origtio));
   } else {
      fprintf(stderr, "WARNING: Attempt to restore serial settings on ");
      fprintf(stderr, "non-serial file descriptor\n");
   }
}

void cleanExit(int code) {
   int i;

   for (i=0; i<numStreams; i++) {
      if (streams[i].type == SERIAL_PORT) {
         restoreSerialSettings(&(streams[i]));
      }
   }

   exit(code);
}

char *filenameForCommPort(char *commName) {
   int i;
   for (i=0; comPorts[i][0]!=0; i++) {
      if (strcmp(commName, comPorts[i][0])==0) {
         return comPorts[i][1];
      }
   }
   return NULL;
}

ioStream *createStreamStruct() {
   if (numStreams+1 >= MAX_IO_STREAMS) {
      printf("Exceeded maximum number of streams!\n");
      cleanExit(1);
   }

   streams[numStreams].fd = -1;
   streams[numStreams].bufLen = 0;
   streams[numStreams].type = 0;
   streams[numStreams].format = 0;
   streams[numStreams].writePreamble = 0;  // valid if format=FRAMED_FORMAT
   streams[numStreams].bePersistent = 0;
   return &(streams[numStreams++]);
}

void deleteStream(ioStream *s) {
   if (s->bePersistent) {
      s->fd = -1;
      return;
   }

   if (s != &(streams[numStreams-1])) { // if not last entry
      // copy the last entry into the hole
      memcpy(s, &(streams[numStreams-1]), sizeof(ioStream));
   }
   numStreams--;
}

int isNum(char *s) {
   if ((s == 0 ) || (*s == 0)) { // if NULL or a null string is passed, fail
      return 0;
   }

   while (*s != 0) {
      if ((*s > '9') || (*s < '0')) {
         return 0;
      }
      s++;
   }

   return 1;
}

void shiftBufferLeft(ioStream *s, int n) {
   int i;

   s->bufLen -= n;

   for (i=0; i < s->bufLen; i++) {
      s->buf[i] = s->buf[i+n];
   }
}

int hexToDecimal(char c) {
   if ((c>='0') && (c<='9')) {
      return c - '0';
   } else if ((c>='a') && (c<='f')) {
      return c - 'a' + 10;
   } else if ((c>='A') && (c<='F')) {
      return c - 'A' + 10;
   } else {
      fprintf(stderr, "ERROR: Bad character in hex value: %c\n", c);
      return 0;
   }
}

int switchToRawUnframedIO(char * arg) {
   if ((arg[0] == '-') && (arg[1] == 'r') && (isNum(arg+2))) {
      if (packetLen > 0) {  // only allowed once!
         printUsage("uartserver");
         cleanExit(0);
      }
      packetLen = atoi(arg+2);
      printf("Setting packet length for raw connections to %d\n", packetLen);
      return 1;
   } else {
      return 0;
   }
}

void writeMessage(int fd, char* buf, int buflen) {
   struct timeval zero_timeout;
   fd_set wfds, efds;

   FD_ZERO(&wfds);
   FD_SET(fd, &wfds);
   FD_ZERO(&efds);
   FD_SET(fd, &efds);

   zero_timeout.tv_sec = 0;
   zero_timeout.tv_usec = 0;

   if (select(fd+1, NULL, &wfds, &efds, &zero_timeout) > 0) {
      write(fd, buf, buflen);
   }
}

void write_bytes(int fd, const void *buf, size_t count) {
#ifdef WRITE_PACE
   int i;
   for (i=0; i<count; i++) {
      write(fd, buf[i], 1);
      usleep(WRITE_PACE);
   }
#else
   write(fd, buf, count);
#endif
}

// input buf is in the format "hh hh ... \n", where h is a hex digit
// should call normalizeMessage before calling this function
void writeRawBytes(int fd, char* buf, int buflen, char format, 
                                                int writePreamble) {
   int i;
   char out;

   if (format == FRAMED_FORMAT) {
      if (writePreamble) {
         write_bytes(fd, uart_preamble_vals, 5);
      }
      write_bytes(fd, uart_frame_vals, 3);
   }

   if ((format == FRAMED_FORMAT) || (format == SF_FORMAT)) {
      out = buflen/3;
      write_bytes(fd, &out, 1);
   }

   i = 0;
   do {
      i++;
      if ((format == RAW_FORMAT) && (i > packetLen)) {
         printf("WARNING: attempt to write a long packet on a raw unframed port\n");
         return;
      }
      out = (hexToDecimal(*(buf++))<<4);
      out |= hexToDecimal(*(buf++));
      write_bytes(fd, &out, 1);
   } while (*(buf++) != '\n');

   if ((format == RAW_FORMAT) && (i < packetLen)) {
      printf("WARNING: padding a short packet written to a raw unframed port\n");
      out = 0;
      for (; i < packetLen; i++) {
         write_bytes(fd, &out, 1);
      }
   }
}

int isHexDigit(char c) {
   return (((c>='0') && (c<='9')) ||
           ((c>='a') && (c<='f')) ||
           ((c>='A') && (c<='F')));
}

int isWhitespace(char c) {
   return ((c == ' ') || (c == '\t') || (c == '\r'));
}

// normalizes buf to the format "hh hh ... \n", where h is a hex digit
// len may be shortened
// the return value is 1 iff the conversion was successful
int normalizeMessage(char *buf, int *len) {
   char out[BUFFER_SIZE];
   int out_i=0;
   int i=0;

   while (1) {
      while ((i < *len) && isWhitespace(buf[i])) { // skip whitespace
         i++;
      }

      if (i >= *len) {
         return 0;     // string can't end here
      }

      if (! isHexDigit(buf[i])) {  // check first hex digit
         return 0;
      }

      out[out_i++] = buf[i++]; // copy byte

      if (i >= *len) {
         return 0;     // string can't end here
      }

      if (! isHexDigit(buf[i])) { // check second hex digit
         return 0;
      }

      out[out_i++] = buf[i++]; // copy byte

      while ((i < *len) && isWhitespace(buf[i])) { // skip whitespace
         i++;
      }

      if (i >= *len) {
         return 0;     // string can't end here
      }

      if (buf[i] == '\n') {  // this is end of message
         out[out_i++] = '\n';  // add a newline to the end

         // update the length and copy the string back
         *len = out_i;
         bcopy(out, buf, *len);

         return 1;   // success!
      }

      out[out_i++] = ' ';
   }
}

// should call normalizeMessage before calling this function
void forwardMessage(char *buf, int n, ioStream *sourceStream) {
   int i;

   for (i=0; i<numStreams; i++) {
      if ((streams[i].type != SERVER_SOCKET) && // don't write to server sock
          (streams[i].fd != -1) &&              // don't write to closed sock
          (&(streams[i]) != sourceStream)) {    // don't repeat to self
         if (streams[i].format == ASCII_FORMAT) {
            writeMessage(streams[i].fd, buf, n);
         } else {
            writeRawBytes(streams[i].fd, buf, n, streams[i].format, 
                          streams[i].writePreamble);
         }
      }
   }
}

void handleServerSocket(ioStream *s) {
   struct sockaddr_in sa;
   int addrlen;
   struct hostent *he;
   char *hostname=NULL;
   ioStream *newStream;
   int fd;
   
   addrlen = sizeof(sa);
   fd = accept(s->fd, (struct sockaddr *) &sa, &addrlen);
   if (fd < 0) {
      if (errno!=EAGAIN) {    // it's nonblocking, so this is ok
         perror("accept()");
      }
      return;
   }

   he = gethostbyaddr((char *) &(sa.sin_addr), 4, AF_INET);
   if (he == NULL) {
      char *bytes = (char *) &(sa.sin_addr);
      sa.sin_addr.s_addr = ntohl(sa.sin_addr.s_addr);
      hostname = (char *) malloc(16);
      sprintf(hostname, "%d.%d.%d.%d", bytes[0], bytes[1], bytes[2], bytes[3]);
   } else {
      hostname = (char *) malloc(strlen(he->h_name)+1);
      strcpy(hostname, he->h_name);
   }

   printf("Got connection from %s:%d to %s\n", hostname, 
                                               ntohs(sa.sin_port), s->name);

   newStream = createStreamStruct();
   newStream->fd = fd;
   newStream->type = CLIENT_SOCKET;
   newStream->format = s->format;
   sprintf(newStream->name, "%s:%d", hostname, ntohs(sa.sin_port));

   if (newStream->format == SF_FORMAT) {
      char buf[2];

      write(newStream->fd, SF_VERSION_STRING, 2);
      read(newStream->fd, buf, 2);
   }
}

char intToHexChar(int n) {
   if (n < 10) {
      return n + '0';
   } else {
      return n - 10 + 'A';
   }
}

char *byteToHexString(char b, char *s) {
   s[0] = intToHexChar((b>>4)&0xf);
   s[1] = intToHexChar(b&0xf);
   s[2] = '\0';
   return s;
}

int fillBuffer(ioStream *s) {
   int n;

   n = read(s->fd, &(s->buf[s->bufLen]), BUFFER_SIZE - s->bufLen);
   if (n <= 0) {   // close or EOF
      if (n < 0) {
         printf("Input %s failed: %s\n", s->name, strerror(errno));
      } else {
         printf("Input %s closed\n", s->name);
      }
      if (s->type == SERIAL_PORT) {
         restoreSerialSettings(s);
      }
      close(s->fd);
      deleteStream(s);
      return 1;
   }

   s->bufLen += n;

   return 0;
}

void handleRawUnframedInput(ioStream *s, int bytesToRead) {
   int i;
   char scratch[3];
   char output[BUFFER_SIZE];
   int j;

   if (s->bufLen < bytesToRead) {
      return;   // not enough bytes in the buffer yet
   }

   // create a message in ASCII format
   j=0;
   for (i=0; i < bytesToRead; i++) {
      byteToHexString(s->buf[i], scratch);
      output[j++]=scratch[0];
      output[j++]=scratch[1];
      if (i < bytesToRead-1) {
         output[j++]=' ';
      } else {
         output[j++]='\n';
      }
   }
   output[j]='\0';

   // print out the message
   printf("%s", output);
   fflush(stdout);

   // forward the message
   forwardMessage(output, j, s);

   // remove the packet bytes from the buffer and keep going
   shiftBufferLeft(s, bytesToRead);
}

void handleSFInput(ioStream *s) {
   int len;

   if (s->bufLen < 2) {
      return;   // not enough bytes in the buffer yet
   }

   len = (s->buf[0] & 0xFF);

   shiftBufferLeft(s, 1);

   handleRawUnframedInput(s, len);
}

void handleRawFramedInput(ioStream *s) {
   if (fillBuffer(s)) {
      return;
   }

   while (1) {
      int i;
      char scratch[3];

      // throw away bytes until we see first byte of uart frame
      for (i=0; (i < s->bufLen) && (s->buf[i] != uart_frame_vals[0]); i++) {
         printf("(%s) ", byteToHexString(s->buf[i], scratch));
      }
      fflush(stdout);

      shiftBufferLeft(s, i);

      // if there aren't enough bytes for a whole frame, wait for more
      if (s->bufLen < 4) {
         return;
      }

      // is this a frame?
      if ((s->buf[1] != uart_frame_vals[1]) || 
          (s->buf[2] != uart_frame_vals[2])) {
         // not a frame, discard the "frame start" byte and keep going
         printf("(%s) ", byteToHexString(s->buf[0], scratch));
         fflush(stdout);
         shiftBufferLeft(s, 1);
      } else {
         // this is the frame
         char output[BUFFER_SIZE];
         int len = s->buf[3];
         int j;

         // is the entire packet in the buffer?
         if (s->bufLen < len + 4) {
            return;  // no, wait for more data
         }

         // print out the frame
         for (i=0; i<4; i++) {
            printf("[%s] ", byteToHexString(s->buf[i], scratch));
         }

         // create a message in ASCII format
         j=0;
         for (i=4; i < len + 4; i++) {
            byteToHexString(s->buf[i], scratch);
            output[j++]=scratch[0];
            output[j++]=scratch[1];
            if (i < len+3) {
               output[j++]=' ';
            } else {
               output[j++]='\n';
            }
         }
         output[j]='\0';

         // print out the message
         printf("%s", output);
         fflush(stdout);

         // forward the message
         forwardMessage(output, j, s);

         // remove the packet bytes from the buffer and keep going
         shiftBufferLeft(s, len + 4);
      }
   }
}

void handleAsciiInput(ioStream *s) {
   int bytesRead;

   bytesRead = read(s->fd, &(s->buf[s->bufLen]), BUFFER_SIZE - s->bufLen);
   if (bytesRead <= 0) {   // close or EOF
      if (bytesRead < 0) {
         printf("Input %s failed: %s\n", s->name, strerror(errno));
      } else {
         printf("Input %s closed\n", s->name);
      }
      close(s->fd);
      deleteStream(s);
   } else {
      int i;
      s->bufLen += bytesRead;

      i = 0;
      while (i < s->bufLen) {
         if (s->buf[i] == '\n') {
            char buf[BUFFER_SIZE];
            int msgLen=i+1;

            bcopy(s->buf, buf, msgLen);

            if (normalizeMessage(buf, &msgLen)) {
               buf[msgLen]=0;
               printf("Forwarding message from %s: %s\n", s->name, buf);

               forwardMessage(buf, msgLen, s);
            } else {
               bcopy(s->buf, buf, i+1);
               buf[i+1]=0;
               fprintf(stderr, "Bad message format: %s\n", buf);
            }

            shiftBufferLeft(s, i+1);
            i=0;
         } else {
            i++;
         }
      }
   }
}

void handleInput(ioStream *s) {
   if (s->type == SERVER_SOCKET) {
      handleServerSocket(s);
   } else if (s->format == ASCII_FORMAT) {
      handleAsciiInput(s);
   } else if (s->format == FRAMED_FORMAT) {
      handleRawFramedInput(s);
   } else if ((s->format == RAW_FORMAT) || (s->format == SF_FORMAT)) {
      if (fillBuffer(s)) {
         return;
      }

      if (s->format == RAW_FORMAT) {
         handleRawUnframedInput(s, packetLen);
      } else if (s->format == SF_FORMAT) {
         handleSFInput(s);
      }
   } else {
      fprintf(stderr, "FATAL ERROR: Invalid stream format.");
      exit(1);
   }
}

// timeout is in msec
void waitForInputs(long timeout) {
   fd_set rfds;
   fd_set efds;
   int highest=0;
   int i;
   struct timeval tv;

   tv.tv_sec = timeout / 1000;
   tv.tv_usec = (timeout % 1000) * 1000;

   FD_ZERO(&rfds);
   FD_ZERO(&efds);
   for (i=0; i<numStreams; i++) {
      if (streams[i].fd > -1) {   // ignore persistent streams that are closed
         if (streams[i].fd > highest) {
            highest = streams[i].fd;
         }
         FD_SET(streams[i].fd, &rfds);
         FD_SET(streams[i].fd, &efds);
      }
   }
   if (select(highest+1, &rfds, NULL, &efds, &tv) > 0) {
      for (i=0; i<numStreams; i++) {
         if ((streams[i].fd > -1) && 
             (FD_ISSET(streams[i].fd, &rfds) || 
              FD_ISSET(streams[i].fd, &efds))
            ) {
            // Note: It's possible, as a result of handleInput(), for the
            //       array of streams to be changed.  Most notably, an entry
            //       can be deleted, shifting others up.  The worst this
            //       can cause is for us to miss reading from a descriptor
            //       this time around and have to catch it on the next 
            //       call to select().
            handleInput(&(streams[i]));
         }
      }
   }
}

void createComm(char *portName, ioStream *s, char format, int moteType) {
   char * filename = filenameForCommPort(portName);
   struct termios newtio;

   strcpy(s->name, portName);
   s->type = SERIAL_PORT;
   s->format=format;

   if (s->format == FRAMED_FORMAT) {
      s->writePreamble = mote_configs[moteType][USE_PREAMBLE];
   }

   /* open serial port for read/write */
   printf("Opening port: %s (%s)\n", portName, filename);
   s->fd = open(filename, O_RDWR|O_NOCTTY);
   if (s->fd < 0) {
      perror("open()");
      cleanExit(1);
   }

   tcgetattr(s->fd, &(s->origtio));

   /* Serial port setting */
   memset(&newtio, 0, sizeof(newtio));
   newtio.c_cflag = mote_configs[moteType][BAUD_RATE] | CS8 | CLOCAL | CREAD;
   newtio.c_iflag = IGNPAR;

   cfsetospeed(&newtio, (speed_t)mote_configs[moteType][BAUD_RATE]);
   cfsetispeed(&newtio, (speed_t)mote_configs[moteType][BAUD_RATE]);

   /* Raw output_file */
   newtio.c_oflag = 0;
   tcflush(s->fd, TCIFLUSH);
   tcsetattr(s->fd, TCSANOW, &newtio);
}

void createServerSocket(int port, ioStream *s, char format) {
   struct sockaddr_in sa;

   printf("Listening to port %d\n", port);

   sa.sin_family=AF_INET;
   sa.sin_port=htons(port);
   sa.sin_addr.s_addr=INADDR_ANY;

   s->fd=socket(PF_INET, SOCK_STREAM, 0);
   if (s->fd < 0) {
      perror("socket()");
      cleanExit(1);
   }

   {
      // Allow immediate socket reuse.
      int reuse_opt = 1;
      if (setsockopt(s->fd, SOL_SOCKET, SO_REUSEADDR, 
                     &reuse_opt, sizeof(reuse_opt)) < 0) {
         perror("setsockopt(SO_REUSEADDR)");
         cleanExit(1);
      }
   }

   if (bind(s->fd, (struct sockaddr *) &sa, sizeof(sa)) < 0) {
      printf("Failure binding to port %d: %s\n", port, strerror(errno));
      cleanExit(1);
   }

   if (listen(s->fd, 5)<0) {
      perror("listen()");
      cleanExit(1);
   }

   // Make it nonblocking.  Otherwise, accept can block even if select 
   // indicated that a new connection was present (if the connection died
   // before the call to accept())
   if (fcntl(s->fd, F_SETFL, O_NONBLOCK)<0) {
      perror("fcntl()");
      cleanExit(1);
   }

   sprintf(s->name, "%d", port);
   s->type = SERVER_SOCKET;
   s->format = format;
}

void createClientSocket(char *hostSpec, ioStream *s, char format) {
   char hostname[strlen(hostSpec)];
   int port = DEFAULT_SERVER_PORT;
   char *colon;
   struct hostent *he;
   struct sockaddr_in sa;

   printf("Connecting to %s\n", hostSpec);

   strcpy(hostname, hostSpec);

   colon = index(hostname, ':');
   if (colon != NULL) {
      *colon=0;
      if (!isNum(colon+1)) {
         printf("Invalid port number in argument: %s\n", hostSpec);
         cleanExit(1);
      }
      port=atoi(colon+1);
   }

   s->type = CLIENT_SOCKET;
   s->bePersistent = usePersistentSockets;
   s->format = format;
   strcpy(s->name, hostSpec);

   he = gethostbyname(hostname);
   if (he == NULL) {
      printf("Unknown host name: %s\n", hostname);
      cleanExit(1);
   }

   sa.sin_family=AF_INET;
   sa.sin_port=htons(port);
   memcpy(&(sa.sin_addr), he->h_addr, he->h_length);

   s->fd=socket(PF_INET, SOCK_STREAM, 0);
   if (s->fd < 0) {
      perror("socket()");
      cleanExit(1);
   }
   if (connect(s->fd, (struct sockaddr *) &sa, sizeof(sa)) < 0) {
      printf("Failure connecting to %s: %s\n", hostSpec, strerror(errno));
      deleteStream(s);
   }

   if (format == SF_FORMAT) {
      char buf[2];

      write(s->fd, SF_VERSION_STRING, 2);
      read(s->fd, buf, 2);
   }
}

int isDigit(char c) {
   return ((c >= '0') && (c <= '9'));
}

void createStreams(int argc, char* argv[]) {
   int i;
   char serial_format = FRAMED_FORMAT;
   char socket_format = ASCII_FORMAT;
   int moteType=MICA;

   // no arguments, assume DEFAULT_COM and DEFAULT_SERVER_PORT
   if (argc == 1) {
      createComm(DEFAULT_COM, createStreamStruct(), FRAMED_FORMAT, MICA);
      createServerSocket(DEFAULT_SERVER_PORT, createStreamStruct(), ASCII_FORMAT);
      return;
   }

   // create a streams record for each item on the command line, which can be
   // COMn, hostname, hostname:port, port
   for (i=1; i<argc; i++) {
      ioStream *newStream = createStreamStruct();
//      printf("Handling argument: %s\n", argv[i]);

      if ((strcmp(argv[i], "-v")==0) || (strcmp(argv[i], "--version")==0)) {
         printf("Version: %s\n", VERSION);
         exit(0);
      } else if ((strcmp(argv[i], "-h")==0) || 
                 (strcmp(argv[i], "--help")==0)) {
         printUsage(argv[0]);
         cleanExit(0);
      } else if ((argv[i][0] == '-') && isDigit(argv[i][1]) && 
                 (argv[i][2] == '\0')) {
         moteType = argv[i][1] - '0';
         if ((moteType == 0) || (moteType > MAX_MOTE_TYPE)) {
            printf("Bad mote type\n");
            printUsage(argv[0]);
            cleanExit(0);
         }
      } else if (strcmp(argv[i], "-sf")==0) {
         socket_format = SF_FORMAT;
      } else if (switchToRawUnframedIO(argv[i])) {
         serial_format = RAW_FORMAT;
         socket_format = RAW_FORMAT;
      } else if (filenameForCommPort(argv[i]) != NULL) {  // is it COMn?
         createComm(argv[i], newStream, serial_format, moteType);
      } else if (isNum(argv[i])) {  // is it a server port number?
         createServerSocket(atoi(argv[i]), newStream, socket_format);
      } else {  // assume it's a host or host:port
         createClientSocket(argv[i], newStream, socket_format);
      }
   }
}

void signalHandler(int signum) {
   switch (signum) {
      case SIGHUP:
         printf("Exiting on SIGHUP\n");
         break;
      case SIGINT:
         printf("Exiting on SIGINT\n");
         break;
      case SIGTERM:
         printf("Exiting on SIGTERM\n");
         break;
      default:
         printf("Exiting on signal %d\n", signum);
   }

   cleanExit(1);
}

void setupSignalHandler() {
   signal(SIGHUP, &signalHandler);
   signal(SIGINT, &signalHandler);
   signal(SIGTERM, &signalHandler);
}

void doPersistenceCheck() {
   int i;

   for (i=0; i<numStreams; i++) {
      if ((streams[i].fd == -1) && (streams[i].type == CLIENT_SOCKET)) {
         createClientSocket(streams[i].name, &(streams[i]), 
                            streams[i].format);
      }
   }
}

int main(int argc, char* argv[]) {
   long lastPersistenceCheck = currentTimeMillis();

   setupSignalHandler();

   createStreams(argc, argv);

   while (1) {
      long time = currentTimeMillis();
      if ((time - lastPersistenceCheck) > PERSISTENCE_CHECK_PERIOD) {
         doPersistenceCheck();
         time = lastPersistenceCheck = currentTimeMillis();
      }
      waitForInputs(PERSISTENCE_CHECK_PERIOD - (time - lastPersistenceCheck));
   }
}
