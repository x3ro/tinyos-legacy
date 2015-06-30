#define SP_DEBUG
#include "sp_debug.inc"


void ud_byte(unsigned char data)
{
  do
    {
      while( (inp(UART_SR) & 0x20) == 0)
	{}; 
      outp(data, UDR);
    }
  while(0);
} 


void ud_init(unsigned char bandwidth)
{
  outp(bandwidth,UBRR);
  inp(UDR);
  outp(0x08,UART_CR);
}

#undef SP_DEBUG




