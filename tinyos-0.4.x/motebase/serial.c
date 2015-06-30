#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <termios.h>
#include <stdio.h>

#define BAUDRATE B9600

int main(int argic, char ** argv) {

int com1,i,stop=0;
int count;
int sofar;
int correct;
char radio[255];
unsigned int reset=0xAA0000AA;
unsigned int rf_enable=0x80000080;
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
/*
    count = write(com1,&reset, 4);
    printf("write %d bytes done\n", count);
*/

/*
    count = write(com1,&text, 6);
    printf("write %d bytes done\n", count);
*/

/*
    count = write(com1,&rf_enable, 4);
    printf("write %d bytes done\n", count);
*/

    sofar = 0;
    correct = 0;
    while(stop == 0) {
	
	count = read(com1, radio, 255); 	
	radio[count]=0;
	for (i=0; i < count; i++) {
	    printf("%x ", 0x000000FF & radio[i]);
	}
	if (count > 0) { 
	    if(radio[0] == 'H' &&
		radio[1] == 'E' &&	
		radio[2] == 'L' &&	
		radio[3] == 'L' &&	
		radio[4] == 'O' &&	
		radio[5] == '?') correct ++;	
	    sofar ++;
	    printf("\ncount=%d\n",count);
	    printf("sofar=%d/%d\t%f\%\n",correct, sofar,(float)correct/(float)sofar*100);
	} else if (count == -1) 
	    perror(":read error\n");

	if (radio[0] == (char) 132)
	   stop=1;
    }

  
    tcsetattr(com1, TCSANOW, &oldtio);
    close(com1);
}






