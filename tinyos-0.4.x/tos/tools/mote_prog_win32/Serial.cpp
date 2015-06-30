#include "PCH.h" // common MicroSoft/Borland Headers
/*
    rs232.c

    RS232 Interface
    Uros Platise (c), 1997
*/
#include "Serial.h"// this is the header file for this source code

/* max measured: B38400 */
#ifndef SER_BAUDRATE
   #define SER_BAUDRATE    B19200
#endif

//------------------------------------------------------------------------------
int TRS232::Open (const char* devName)
{
//   struct termios pmode;

  // open device
//   if((serline = open(devName.c_str(), O_RDWR | O_NDELAY)) < 0)
   if((serline = open(devName, O_RDWR)) < 0)
   {
      error(string("Cannot open the specified device."));
      exit(1);
   }

 
  // reopen port
   int fd = serline;
   serline = open(devName, O_RDWR);
   if(serline < 0)
   {
      error(string("Error at closing device."));
      exit(1);
   }
   close(fd);
   return serline;
}
//------------------------------------------------------------------------------
int TRS232::Close ()
{
   return close(serline);
}
//------------------------------------------------------------------------------
unsigned char TRS232::changeOrder(unsigned char byte)
{
   unsigned char cb = 0;
   int i;
   for(i=0;i<8;i++)
   {
      cb <<= 1;
      cb |= byte&1;
      byte >>=1;
   }
   return cb;
}
//------------------------------------------------------------------------------
int TRS232::Send (const unsigned char* queue, int size)
{
   int i, ret;
   if(chOrder==true)
   {
      unsigned char* tQueue = new (unsigned char) (size);
      for(i=0;i<size;i++)
         tQueue[i] = changeOrder(queue[i]);
      ret = write (serline, tQueue, size);
      delete tQueue;
   }
   else
   {
      ret = write (serline, queue, size);
   }
   return ret;
}
//------------------------------------------------------------------------------
int TRS232::Recv (unsigned char* queue, int queueSize, timeval* timeout)
{
   int i, size;
   /* TODO : fix serial comm */
//   fd_set rfds;
//   FD_ZERO (&rfds); FD_SET (serline,&rfds);
//   if((i=select(getdtablesize(),&rfds,NULL,NULL, timeout))==-1)
   {
//      throw Error_C();
   }
   if(i==0)
   {
      throw Error_Device ("Device is not responding.");
   }
   size = read(serline, queue, queueSize);
   if(chOrder==true)
   {
      for(i=0;i<size;i++)
         queue[i] = changeOrder(queue[i]);
   }
   return size;
}
//------------------------------------------------------------------------------
void TRS232::error (const string& errMsg)
{
   cout << "RS-232: " << errMsg << '\n';
}
//------------------------------------------------------------------------------
struct timeval time_out;
//------------------------------------------------------------------------------
int TSPI::Send (unsigned char* queue, int queueSize, int rec_queueSize)
{
   if(rec_queueSize==-1)
   {
      rec_queueSize = queueSize;
   }
   SPIdev->Send(queue, queueSize);

   int i=0;
   time_out.tv_sec = 1;
   time_out.tv_usec = 0;

   while(i<rec_queueSize)
   {
      i+=SPIdev->Recv(&queue[i], rec_queueSize - i, &time_out);
   }
   return i;
}

