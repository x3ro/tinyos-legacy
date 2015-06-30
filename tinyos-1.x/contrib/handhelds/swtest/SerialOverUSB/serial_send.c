/*
 *   Read usb-dongle attached sd card
*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include <unistd.h>
#include <fcntl.h>
#include <termios.h>
#include <inttypes.h>
#include <sys/ioctl.h>

#include <linux/types.h>

void bailout(char *msg)
{
    perror(msg);
    fprintf(stderr,"errno=%d\n", errno);
    exit(-1);
}

int main(int argc, char **argv)
{
  int fd, i, n;
  unsigned char vvv[256], * scout;
  int rs232_fd;
  struct termios ios;

  /* Create the socket */
  rs232_fd = open("/dev/ttyUSB1", O_WRONLY);
  if(rs232_fd < 0) 
    bailout("socket");
  memset(&ios, 0, sizeof(ios));
  ios.c_cflag=B115200|CLOCAL|CREAD|CS8;
  ios.c_cc[VMIN]=1;
  tcsetattr(rs232_fd, TCSANOW, &ios);

  for(i = 0; i < 256; i++)
    vvv[i] = i;

  i = 0;
  for(;;){
    if((n = write(rs232_fd, (vvv + i), 1)) > 0)
      fprintf(stderr, "%02x ", *(vvv + i));
    i++;
    
    if(i == 100){
      //      usleep(500);
      i = 0;
    }
  }
  close(rs232_fd);
}


