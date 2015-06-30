#include <stdarg.h>

//#include <stdio.h>

//#define SCRATCH 16
#define SCRATCH 64
#define BUF_LEN 256
char debugbuf[BUF_LEN];



//init comm port (56K baud, mica2 only, use 19K baud for mica2dot, mica....) for debug
// call this from startup routine
void init_debug(){           
  outp(0,UBRR0H); 
  outp(15, UBRR0L);                              //set baud rate
  outp((1<<U2X),UCSR0A);                         // Set UART double speed
  outp(((1 << UCSZ1) | (1 << UCSZ0)) , UCSR0C);  // Set frame format: 8 data-bits, 1 stop-bit
  inp(UDR0); 
  outp((1 << TXEN) ,UCSR0B);   // Enable uart reciever and transmitter
 }

//init comm port (19K baud) for mica2dot for debug
// call this from startup routine
void init_debug_mica2dot(){
    outp(0,UBRR0H);            // Set baudrate to 19.2 KBps
    outp(12, UBRR0L);
    outp(0,UCSR0A);            // Disable U2X and MPCM
    outp(((1 << UCSZ1) | (1 << UCSZ0)) , UCSR0C);
    inp(UDR0); 
    outp((1 << TXEN) ,UCSR0B);
 }

// output a char to the uart
void UARTPutChar(char c) {
  if (c == '\n')
    UARTPutChar('\r');
  loop_until_bit_is_set(UCSR0A, UDRE);
  outb(UDR0,c);
}

void writedebug() {
  int i = 0;
  UARTPutChar('\n');                //write a carriage return 1st          
  while (debugbuf[i] != '\n') 
    UARTPutChar(debugbuf[i++]);
//    UARTPutChar('\n');
  
}
#define SPRINTF              //use this sprintf function
#ifdef SPRINTF
int sprintf(uint8_t *buf, const uint8_t *format, ...)
/* simplified sprintf */
{
  uint8_t scratch[SCRATCH];
  uint8_t format_flag;
  uint16_t u_val=0, base;
  uint8_t *ptr;
  va_list ap;
  bool b_ChkForNegInt = FALSE;

  va_start (ap, format);
  for (;;){
    while ((format_flag = *format++) != '%'){      /* Until '%' or '\0' */
      if (!format_flag){va_end (ap); return (0);}
      *buf = format_flag; buf++; *buf=0;
    }
    b_ChkForNegInt = FALSE;
    switch (format_flag = *format++){

    case 'c':
      format_flag = va_arg(ap,int);
    default:
      *buf = format_flag; buf++; *buf=0;
      continue;
    case 'S':
    case 's':
      ptr = va_arg(ap,char *);
      strcat(buf, ptr);
      continue;
    case 'o':
      base = 8;
      *buf = '0'; buf++; *buf=0;
      goto CONVERSION_LOOP;
    case 'i':
        b_ChkForNegInt = TRUE;
   //     if (((int)u_val) < 0){
   //     u_val = - u_val;
   //     *buf = '-'; buf++; *buf=0;
   //   }
      /* no break -> run into next case */
    case 'u':
      base = 10;
      goto CONVERSION_LOOP;
    case 'x':
      base = 16;

    CONVERSION_LOOP:
      u_val = va_arg(ap,int);
      if (b_ChkForNegInt){
        if (((int)u_val) < 0){
          u_val = - u_val;
          *buf = '-'; buf++; *buf=0;
        }
      }
     
      ptr = scratch + SCRATCH;
      *--ptr = 0;
      do {
        char ch = u_val % base + '0';
        if (ch > '9')
          ch += 'a' - '9' - 1;
        *--ptr = ch;
        u_val /= base;
      } while (u_val);
      strcat(buf, ptr);
      buf += strlen(ptr);
    }
  }
}
#endif

#define SO_NO_DEBUG 0
#define SO_DEBUG             //turn on debug output
#ifdef SO_DEBUG
#define SODbg(__x,__args...) { \
	char bStatus;			\
	if(__x != SO_NO_DEBUG){  \
      bStatus=bit_is_set(SREG,7);	\
	  cli();				\
      sprintf(debugbuf,__args);	\
      writedebug();			\
	  if (bStatus) sei();		\
	 }    \
    }
#else
#define SODbg(__x,__args...)
#endif


