#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <termios.h>
#include <stdio.h>
#include "timing.h"

//#define BAUDRATE B9600
#define BAUDRATE B19200

int main(int argic, char ** argv) {

int com1,i,stop=0;
int count;
int sofar;
int correct;
double start;
char radio[255];
unsigned int reset=0xAA0000AA;
unsigned int rf_enable=0x80000080;
int j;
char text[6]="hello ";

/* unsigned int readeprom[3] = {0x86050002, 0x4A004A00, 0x02000000};*/
char readeprom[9] = {134, 5, 0, 2, 65, 0, 65, 0, 129};
char writeeprom[10] = {134, 6, 0, 9, 65, 0, 65, 0, 210, 91};
unsigned int data=0x01020304;
 
struct termios oldtio, newtio;

    /* open com1 for read/write */ 
    com1 = open("/dev/ttyS0", O_RDWR|O_NOCTTY);
    if (com1 == -1)
	perror(": com1 open fails\n");
    printf("com1 opens ok\n");

    /* save old serial port setting */
    tcgetattr(com1, &oldtio);
    bzero(&newtio, sizeof(newtio));

    newtio.c_cflag = BAUDRATE | CRTSCTS | CS8 | CLOCAL | CREAD;
    newtio.c_iflag = IGNPAR | ICRNL;

    /* Raw output */
    newtio.c_oflag = 0;

    tcflush(com1, TCIFLUSH);
    tcsetattr(com1, TCSANOW, &newtio);
    sofar = 0;
    correct = 0;
    start = get_seconds();
    for(j = 0; j < 30; j++){
	for(i = 0; i < 30; i ++){radio[i]=30 - i + 5;}
	i = 0;
//COMMAND
	radio[i] = 5;i ++;
	radio[i] = 4;i ++;
	radio[i] = 0x10;i ++; 
	radio[i] = 4;i ++; 
	radio[i] = 0;i ++; 
	radio[i] = 0;i ++; 
	radio[i] = 0;i ++; 
	radio[i] = 0;i ++; 
	radio[i] = 0x7e;i ++; 
	radio[i] = 1;i ++; 
	radio[i + 14] = j;i ++; 

	printf("Writing data....");
    write(com1, radio, 30);
	printf("done\n");
    count = 0;
    stop = 0;
    while(stop == 0) {
	readHeader(com1);
	count = 0;
	stop = 1;
	while(count < 28) count += read(com1, radio + count, 28 - count); 	
	if(count >= 0){
		radio[count] = 0;
		printf("data: %x\n", count);
		for(i = 0; i < 28; i ++){
			printf("%x,", radio[i]);
		}
		printf("\n");
		count = 0;
	}
	if (radio[0] == (char) 132)
	   stop=1;
	radio[0] = 0;
	radio[0] = 5;
	radio[0] = 0;
	radio[0] = 0;
	//stop = 0;
//	printf("\nwriting..\n");
	//write(com1, radio, 30);
//	printf("done writing..\n");
     }
   } 
    printf("total: %f\n", (get_seconds() - start)/(double)30);
    tcsetattr(com1, TCSANOW, &oldtio);
    close(com1);
}

int readFull(int file, char* buf, int length){
  int count = 0;
  int loops = 0;
  int added = 0;
  //  printf("readFull called with length %d\n", length);
  while(count < length){
    added = read(file, buf+count, length - count);
    if(added > 0){
        printf("read full: read %d, or %d of %d\n", added, count+added, length);
        count += added;
        loops = 0;
    }else{
      loops;
      if(loops > 4000 && count == 0) {
#ifdef READFULLDEBUG
          if(count > 0) printf("read abort\n");
#endif
          return -1;
      }
    }
	}
return 1;
}

int readHeader(int file){
    char scratch[200];
    int place = 0;
    int err;
    int i;
    bzero(scratch, 200);
    err = readFull(file, scratch, 1);
	printf("looking for header:, %x, %x, %x\n", scratch[0], scratch[1], scratch[2]);
    if(err == -1) return err;

while((scratch[0] != (char)0x7e)){
        printf("%x\n", scratch[0]);
	place++;
        err = readFull(file, scratch, 1);
        printf("Header: %d\n", scratch[0]&0xFF);
        if(err == -1) return err;
	if(place == 190) place = 0;
    }
   printf("header found\n");
   return 1;
}


