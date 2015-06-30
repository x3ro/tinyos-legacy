/*
 * Copyright (C) 2003-2005 the University of Southern California.
 * All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or (at
 * your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public
 * License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA.
 *
 * In addition to releasing this program under the LGPL, the authors are
 * willing to dual-license it under other terms. You may contact the authors
 * of this project by writing to Wei Ye, USC/ISI, 4676 Admirality Way, Suite 
 * 1001, Marina del Rey, CA 90292, USA.
 */
/*
 * Author: Wei Ye
 *
 * This program read debugging bytes from UART, and display it on screen.
 * On the mote side, it should define UART_DEBUG_ENABLE and include uartDebug.h.
 * If a server's IP address is provided when running uartByte, the program
 * will forward bytes to the server, instead of displaying them on screen.
 *
 * If running a server, it will collect the debugging bytes from each node
 * through the UDP socket, and save it into a log file. The program is
 * uartDebugServer.c. It is useful to debug coherent events on several nodes.
 *
 */

#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <termios.h>
#include <string.h>
#include <unistd.h>
#include <sys/time.h>
#include <time.h>

#define BAUDRATE_MICA B19200 // baudrate for Mica
#define BAUDRATE_MICA2 B57600 // baudrate for Mica2
#define SERIAL_DEVICE "/dev/ttyS0" //the port to use.
//#define SERIAL_DEVICE "/dev/ttyUSB0" //the port to use.

// for socket
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>

#define SERVER_PORT 5322
#define BUF_LEN 40

int input_stream;
char input_buffer[BUF_LEN];
long startTime;  // starting time in second

// for sending result via a UDP socket
int sockfd;
struct sockaddr_in their_addr; // connector's address information
struct hostent *he;
//char *serverName = "128.9.160.147";  // scadds ip address
//char *serverName = "127.0.0.1";  // local ip address
char *serverName = NULL;
char *platName = NULL;

void print_usage(void);
void open_input(void);
void setup_socket(void);
void read_forward(void);

int main(int argc, char ** argv) {
   if (argc == 1 || argc > 3) {
      print_usage();
      printf("Error: invalid number of parameters!\n");
      exit(1);
   } else if (argc == 3) {
      serverName = argv[2];  // get UDP server's IP address
   }
   platName = argv[1];  // get mote platform's name
   open_input();
   if (serverName != NULL) setup_socket();
   while(1){
	read_forward();
   }
}

void print_usage(){
    //usage...
	printf("Usage: uartByte platform [IP_addr_of_server]\n");
	printf("  This program reads in data from ");
	printf(SERIAL_DEVICE);
    printf(" and display it on screen.\n");
    printf("Parameters:\n");
    printf("  platform: mica or mica2.\n");
	printf("  IP_address_of_server: if specified, will forward bytes instead of displaying.\n");
}


void open_input(){
   char *platform[2] = {"mica", "mica2"};
   time_t timep;
   struct timeval sTime;
   /* open input_stream for read/write */ 
   struct termios newtio;
   input_stream = open(SERIAL_DEVICE, O_RDWR|O_NOCTTY);
   if (input_stream == -1) {
      printf("Input_stream open failed!\n");
      printf("Make sure the user has permission to open device.\n");
      exit(1);
   }

   /* Serial port setting */
   bzero(&newtio, sizeof(newtio));
   if (strcmp(platName, platform[0]) == 0) {
      newtio.c_cflag = BAUDRATE_MICA | CS8 | CLOCAL | CREAD;
   } else if (strcmp(platName, platform[1]) == 0) {
      newtio.c_cflag = BAUDRATE_MICA2 | CS8 | CLOCAL | CREAD;
   } else {
      print_usage();
      printf("Error: Unknown platform!\n");
      exit(1);
   }
   newtio.c_iflag = IGNPAR;

   /* Raw output_file */
   newtio.c_oflag = 0;
   tcflush(input_stream, TCIFLUSH);
   tcsetattr(input_stream, TCSANOW, &newtio);

   printf("input_stream opens ok\n");

   // record starting time
   timep = time(NULL);
   printf("\nTesting starts at %s\n", ctime(&timep));
   gettimeofday(&sTime, NULL);  // record starting time
   startTime = sTime.tv_sec;
}


void setup_socket()
{
   if ((he=gethostbyname(serverName)) == NULL) {  // get the host info
       perror("gethostbyname");
       exit(1);
   }

   if ((sockfd = socket(AF_INET, SOCK_DGRAM, 0)) == -1) {
       perror("socket");
       exit(1);
   }

   their_addr.sin_family = AF_INET;     // host byte order
   their_addr.sin_port = htons(SERVER_PORT); // short, network byte order
   their_addr.sin_addr = *((struct in_addr *)he->h_addr);
   memset(&(their_addr.sin_zero), '\0', 8);  // zero the rest of the struct

}
   

void read_forward(){
   int count, i, numbytes;
   struct timeval timeStamp;
   long totalTime;
   uint8_t hours, minutes, seconds;
   uint16_t milisec;
   bzero(input_buffer, BUF_LEN);
   do {
      count = read(input_stream, input_buffer, BUF_LEN);
   } while (count == 0);
   // read in some bytes, forward them now
   if (serverName == NULL) {
      gettimeofday(&timeStamp, NULL);
      totalTime = timeStamp.tv_sec - startTime; // total seconds
      seconds = (uint8_t)(totalTime % 60);
      totalTime = (totalTime - seconds) / 60;   // total minutes
      minutes = (uint8_t)(totalTime % 60);
      totalTime = (totalTime - minutes) / 60;   // total hours
      hours = (uint8_t)(totalTime);
      milisec = (uint16_t)(timeStamp.tv_usec/1000);
      printf("At %02d:%02d:%02d.%03d\n", 
         hours, minutes, seconds, milisec);
      for(i = 0; i < count; i ++){
         //printf("   %d\n", input_buffer[i] & 0xff);
         printf("   %u\n", input_buffer[i] & 0xff);
         //printf("   %x\n", input_buffer[i] & 0xff);
      }
      printf("\n");
   } else {
      // send result to server
      if ((numbytes = sendto(sockfd, input_buffer, count, 0,
         (struct sockaddr *)&their_addr, sizeof(struct sockaddr))) == -1) {
         perror("sendto");
         exit(1);
      }
   }
} 
