#include "PCH.h" // common MicroSoft/Borland Headers
/*
    PSPI.C

    Originally written by Sergey Larin.
    Corrected by Denis Chertykov.
    Module for Downloading Through the Parallel Port
    Ported to C++ Builder 5.0 for Windows by Mike Bechtold
    Hardware Driver is by TVicHW32
*/

#include "PSPI.h" // this is the header file for this source code
#include "IO_Cards.h"

int parport_base = LPT1;
static long n_per_ms = 10000;

static void big_delay (volatile int i)
{
   i = 40;
   for(; i > 0; i--);
}

static void var_delay (volatile int i)
{
   //i *= 10;
   for(; i > 0; i--);
}

//------------------------------------------------------------------------------
// classes starts here
//------------------------------------------------------------------------------
PSPI::PSPI (void)
{
   speed = 200;
   NO_VERIFY = 0;
   port_enabled = false;
   if(!IsDriverOpened())
   { // driver error
      perror("OpenTVicHW32");
      throw Error_Device("PSPI","Cannot open port.");
   }

   cout << "pspi opened\n";
   SET_RESET_HIGH(); big_delay(400);// sck = 0, reset = 1
   SET_SCLK_LOW();   big_delay(400);// sck = 0, reset = 0
   SET_RESET_HIGH(); big_delay(400);// sck = 0, reset = 1
   SET_RESET_LOW();  big_delay(400);// sck = 0, reset = 0
   port_enabled = true;
   
}
//------------------------------------------------------------------------------
PSPI::~PSPI ()
{
   SET_RESET_HIGH(); big_delay(400); // sck = 0, reset = 1
}
//------------------------------------------------------------------------------
int PSPI::Send (unsigned char* queue, int queueSize, int rec_queueSize)
{
   unsigned char *p = queue, ch;
   unsigned char* flash = queue;
 // printf(" command: %x,%x,%x,%x  ", flash[0],flash[1],flash[2],flash[3]);
   int i = queueSize;  
   while(i--)
   {
      ch = send_recv (*p);
      *p++ = ch;
   }
  // printf("response : %x,%x,%x,%x\n", flash[0],flash[1],flash[2],flash[3]);
  
   return queueSize;
}
//------------------------------------------------------------------------------
void PSPI::clk (void)
{
   SET_SCLK_LOW();   big_delay(speed); // sck = 0, reset = 0
   SET_RESET_HIGH(); big_delay(speed); // sck = 0, reset = 1
   SET_RESET_LOW();  big_delay(speed); // sck = 0, reset = 0

   SET_SCLK_HIGH();  big_delay(speed); // sck = 1, reset = 0
   SET_SCLK_LOW();   big_delay(speed); // sck = 0, reset = 0
}
//------------------------------------------------------------------------------
unsigned char PSPI::send_recv (unsigned char b)
{
   unsigned char received=0;
   for(int i=0, BitPos = 0x80; i<8; i++, BitPos >>= 1)
   {
      if(b & BitPos)
         SET_DOUT_HIGH();

      else
         SET_DOUT_LOW();

      //var_delay(speed); // ms
      SET_SCLK_HIGH(); //var_delay(speed); // sck = 1, reset = 0
      if(Is_DIN_HIGH())
         received |= BitPos;
      SET_SCLK_LOW(); 
	  //var_delay (speed); // sck = 0, reset = 0

   }
//   printf("%x, %x\n", b, received);
   return received;
}
//------------------------------------------------------------------------------
