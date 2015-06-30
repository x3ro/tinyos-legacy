/*
  Serial.h

  (c) copyright 1997, Uros Platise
*/

#ifndef __Serial
#define __Serial

#define string char

#include <WinSock2.h>
// Top Level Interface for Hardware Devices

class TDev
{
public:
   virtual int Open (const string&) = 0;
   virtual int Send (const unsigned char*, int) = 0;
   virtual int Recv (unsigned char*, int, timeval*) = 0;
   virtual void error (const string&) = 0;
   virtual int Close () = 0;
   virtual void bitOrentation (bool MSB_first) = 0;
   virtual ~TDev () { };
};

// RS232 Interface realization

class TRS232 : public TDev
{
public:
   int Open (const char*);
   int Close ();
   int Send (const unsigned char*, int);
   int Recv (unsigned char*, int, timeval*);
   virtual void error (const string&);
   void bitOrentation (bool MSB_first) { chOrder=MSB_first; }

   TRS232 (): chOrder (false), serline (0) { }
   ~TRS232 () { Close(); }

   bool chOrder;

private:
   int serline;
   unsigned char changeOrder (unsigned char);
};

// SPI Interface

class TSPI
{
public:
   int Send (unsigned char*, int, int rec_queueSize=-1);
   TSPI (TDev *device)  { SPIdev = device; }
private:
   TDev *SPIdev;
};

#endif
