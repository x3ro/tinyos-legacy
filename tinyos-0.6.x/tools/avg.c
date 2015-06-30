#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <termios.h>
#include <stdio.h>
#include "timing.h"
#include <sys/time.h>
struct timespec delay, delay1;
struct timeval tv;



#define BAUDRATE B19200
//#define BAUDRATE B9600

int main(int argic, char ** argv) {
int output = 0;
int count = 0;
char buffer[40];
int cnt[255];
int sum[255];
int i;
    output = open("foo.data", O_RDWR);
    for(i = 0; i < 256; i ++){
	cnt[i] = 0;
	sum[i] = 0;
    }
    if(output) printf("file open\n");
    while(count += read(output, buffer + count, 38 - count)){; 	
	printf("read data: %d\n", count);
	if(count >= 0){
		int source = get_source(buffer);
		printf("%x, %d ", source, buffer[24]);
		buffer[count] = 0;
		sum[source] += buffer[24];
		cnt[source] += 1;
		for(i = 0; i < 29; i ++){
			printf("%x,", buffer[i] & 0xff);
		}
		printf("\n");
		count = 0;
	}
	count = 0;
   } 
   for(i = 0; i < 0x60; i ++){
	if(i == 0x50 || i == 0 || i == 0x51 || i == 0x52)
	printf("%x, %f, %d, %d\n", i, (float)sum[i]/(float)cnt[i], sum[i], cnt[i]);
   }
   printf("done\n");
   close(output);
   exit(0);
}


int get_source(char* data){
 int i;
  char tmp = data[2];
  data[2] = data[1];
  data[1] = tmp;
  for(i = 1; i < 5; i ++){
	if(data[i] == 0) return data[i-1];
  }
  return 255;
}
