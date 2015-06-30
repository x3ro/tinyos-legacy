/*
	Serial.C
	
	Serial Interface
	Uros Platise, (c) 1997-1999
*/

#include <sys/time.h>
#include <sys/ioctl.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include "Global.h"
#include "Serial.h"

int TSerial::Tx(unsigned char* queue, int queue_size){
  return write(serline, queue, queue_size);
}

int TSerial::Rx(unsigned char* queue, int queue_size, timeval* timeout){
  int ret;
  fd_set rfds;
  FD_ZERO(&rfds); FD_SET(serline,&rfds);
  if ((ret=select(getdtablesize(),&rfds,NULL,NULL, timeout))==-1){
    throw Error_C();
  }
  if (ret==0){throw Error_Device("Programmer is not responding.");}
  int size = read(serline, queue, queue_size);  
  return size;
}

int TSerial::Send(unsigned char* queue, int queue_size, int rec_queue_size){
  Tx(queue, queue_size);
  struct timeval time_out;
  time_out.tv_sec = 1;
  time_out.tv_usec = 0;
  if (rec_queue_size==-1){rec_queue_size = queue_size;}
  int total_len=0;  
  while(total_len<rec_queue_size){
    total_len += Rx(&queue[total_len], rec_queue_size - total_len, &time_out);
  }
  return total_len;
}

/* Constructor/Destructor
*/

TSerial::TSerial(){
  struct termios pmode;
  const char* dev_name = "/dev/avr";
  const char* val;
  speed_t speed = B19200;	/* default speed */
  
  struct TSpeed{
    const char* arg;
    speed_t speed;
  };
  const TSpeed speed_array[] = {
    {"1200", B1200},
    {"2400", B2400},
    {"4800", B4800},
    {"9600", B9600},
    {"19200", B19200},
    {"38400", B38400},
    {"57600", B57600},
    {"115200", B115200},
    {"", 0}
  };
  
  /* Parse Command Line Parameters */
  if (strcmp(GetCmdParam("-dprog"), "stk500") == 0) {
    speed = B115200;        /* default STK500 speed */
  }
  if ((val=GetCmdParam("-dserial"))){dev_name = val;}
  if ((val=GetCmdParam("-dspeed"))){
    const TSpeed* speed_item = speed_array;
    for (;speed_item->arg[0] != 0; speed_item++){
      if (strcmp(speed_item->arg, val) == 0) {
	speed = speed_item->speed;
	break;
      }
    } 
    if (speed_item->arg[0]==0){throw Error_Device("-dspeed: Invalid speed.");}
  }
  
  /* Open port and set serial attributes */
  if ((serline = open(dev_name, O_RDWR | O_NOCTTY | O_NONBLOCK)) < 0) {
    throw Error_C();
  }  
  tcgetattr(serline, &pmode);
  saved_modes = pmode;

  cfmakeraw(&pmode);
  pmode.c_iflag &= ~(INPCK | IXOFF | IXON);
  pmode.c_cflag &= ~(HUPCL | CSTOPB | CRTSCTS);
  pmode.c_cflag |= (CLOCAL | CREAD);
  pmode.c_cc [VMIN] = 1;
  pmode.c_cc [VTIME] = 0;

  cfsetispeed(&pmode, speed);
  cfsetospeed(&pmode, speed);
  tcsetattr(serline, TCSANOW, &pmode);

#if 0
  /* Reopen port */
  int fd = serline;
  if ((serline = open(dev_name, O_RDWR | O_NOCTTY)) < 0){throw Error_C();}
  close(fd);
#else
  /* Clear O_NONBLOCK flag.  */
  int flags = fcntl(serline, F_GETFL, 0);
  if (flags == -1) { throw Error_C(); }
  flags &= ~O_NONBLOCK;
  if (fcntl(serline, F_SETFL, flags) == -1) { throw Error_C(); }
#endif
}

TSerial::~TSerial(){
  tcsetattr(serline, TCSADRAIN, &saved_modes);
  close(serline);
}

