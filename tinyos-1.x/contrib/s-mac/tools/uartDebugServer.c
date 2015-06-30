/* uartDebugServer.c
 *
 * This program receives debugging bytes from each node via a UDP socket,
 * and save them into a log file that can be parsed later by uartDebugParser.c.
 * If a state-event table is included, it will display debugging message 
 * on the screen. Otherwise it will only display raw data.
 * 
 * To use this program, you need to connect each mote to a PC, and run 
 * uartByte.c on the PC. On the mote side, you need to define UART_DEBUG_ENABLE
 * and include uartDebug.h in the component you want to debug.
 * 
 * Author: Wei Ye (USC/ISI)
 * Date: 03/10/2003
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/time.h>
#include <time.h>

// if debug another component, comment out following line
// or include a corresponding debug table
#include "smacDebugTab.h"

#define MYPORT 5322    // the port users will be connecting to

#define MAXBUFLEN 100

int main(int argc, char ** argv)
{
   int sockfd;
   struct sockaddr_in my_addr;    // my address information
   struct sockaddr_in their_addr; // connector's address information
   int addr_len, numbytes, i;
   char buf[MAXBUFLEN];
   // time stamping
   long startTime;  // starting time in second
   time_t timep;
   struct timeval sTime;
   struct timeval timeStamp;
   long totalTime;
   uint8_t nodeId, days, hours, minutes, seconds, milisec;
   FILE *logFile;
   char* logFileName;
   char saveTime;

   if (argc == 2) {
      saveTime = 0;
      if (strncmp(argv[1], "-", 1) == 0) {
         printf("Error: no log file specified.\n");
         exit(1);
      }
      logFileName = argv[1];
   } else if (argc == 3) {
      if (strcmp(argv[1], "-t")) {
         printf("Wrong option: %s\n", argv[1]);
         exit(1);
      }
      saveTime = 1;
      logFileName = argv[2];
   } else {
      printf("Usage: uartDebugServer [-t] logFile\n");
      printf("Options: -t save timestamp\n");
      exit(1);
   }
   
   if ((logFile = fopen(logFileName, "w")) == NULL) {
      printf("Error: can't open log file %s.\n", logFileName);
      exit(1);
   }
      
   // record starting time
   printf("Logs are saved to %s \n", logFileName);
   if (saveTime) {
      printf("time-stamped\n");
      fprintf(logFile, "time-stamped\n");
   } else {
      printf("no timestamp\n");
      fprintf(logFile, "no_timestamp\n");
   }
   timep = time(NULL);
   printf("\ntest started at %s\n", ctime(&timep));
   fprintf(logFile, "test started at %s\n", ctime(&timep));
   gettimeofday(&sTime, NULL);  // record starting time
   startTime = sTime.tv_sec;

   if ((sockfd = socket(AF_INET, SOCK_DGRAM, 0)) == -1) {
      perror("socket");
      exit(1);
   }

   my_addr.sin_family = AF_INET;         // host byte order
   my_addr.sin_port = htons(MYPORT);     // short, network byte order
   my_addr.sin_addr.s_addr = INADDR_ANY; // automatically fill with my IP
   memset(&(my_addr.sin_zero), '\0', 8); // zero the rest of the struct

   if (bind(sockfd, (struct sockaddr *)&my_addr,
      sizeof(struct sockaddr)) == -1) {
      perror("bind");
      exit(1);
   }

   addr_len = sizeof(struct sockaddr);
   // recvfrom will block if no packet arrives
   while (1) {
      if ((numbytes=recvfrom(sockfd, buf, MAXBUFLEN-1 , 0,
	     (struct sockaddr *)&their_addr, &addr_len)) == -1) {
         perror("recvfrom");
         exit(1);
      }
   
      // get time stamp
      gettimeofday(&timeStamp, NULL);
      totalTime = timeStamp.tv_sec - startTime; // total seconds
      seconds = (uint8_t)(totalTime % 60);
      totalTime = (totalTime - seconds) / 60;   // total minutes
      minutes = (uint8_t)(totalTime % 60);
      totalTime = (totalTime - minutes) / 60;   // total hours
      //hours = (uint8_t)(totalTime % 24);
      //days = (uint8_t)(totalTime - hours) / 24; // total days
      hours = (uint8_t)(totalTime);
      milisec = (uint16_t)(timeStamp.tv_usec/10000);
   
      //nodeId = *((uint8_t*)(&their_addr.sin_addr.s_addr) + 3) - 40; // for ISI
      nodeId = *((uint8_t*)(&their_addr.sin_addr.s_addr) + 3);
      
      printf("Node %d at %02d:%02d:%02d.%02d\n", 
            nodeId, hours, minutes, seconds, milisec);
      if (saveTime) {
         fprintf(logFile, "%d %d %d %d %d\n",
            nodeId, hours, minutes, seconds, milisec);
      } else {
         fprintf(logFile, "%d\n", nodeId);
      }
      fprintf(logFile, "%d\n", numbytes);
             
      // print out debugging info
      for(i = 0; i < numbytes; i++){
         uint8_t msgNo = (uint8_t)buf[i];
#ifdef STATE_EVENT
         if (msgNo >= sizeof(stateEvent)) exit(1);
         printf("   %s\n", stateEvent[msgNo]);
#else
         printf("   %d\n", msgNo);
#endif
         fprintf(logFile, "%d\n", msgNo);
      }
      printf("\n");
      fprintf(logFile, "\n");
      fflush(logFile);
   }
   close(sockfd);
   fclose(logFile);

   return 0;
}
