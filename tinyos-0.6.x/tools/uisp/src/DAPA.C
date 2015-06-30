/*
	DAPA.C

	Direct AVR Parallel Access (c) 1999
	
	Originally written by Sergey Larin.
	Corrected by 
	  Denis Chertykov, 
	  Uros Platise and 
	  Marek Michalkiewicz
*/

#ifndef NO_DAPA
//#define DEBUG

#include <stdio.h>
#include <stdlib.h>
#include <errno.h>

#ifndef NO_DIRECT_IO

/* Linux and FreeBSD differ in the order of outb() arguments.
   XXX any other OS/architectures with PC-style parallel ports?
   XXX how about the other *BSDs?  */

#if defined(__linux__) && defined(__i386__)

#include <sys/io.h>

#define ioport_read(port)         inb(port)
#define ioport_write(port, val)   outb(val, port)
#define ioport_enable(port, num)  ioperm(port, num, 1)
#define ioport_disable(port, num) ioperm(port, num, 0)

#elif defined(__CYGWIN__)

#include "cygwinp.h"

#define ioport_read(port)         inb(port)
#define ioport_write(port, val)   outb(val, port)
#define ioport_enable(port, num)  ioperm(port, num, 1)
#define ioport_disable(port, num) ioperm(port, num, 0)

#elif defined(__FreeBSD__) && defined(__i386__)

#include <sys/fcntl.h>
#include <machine/cpufunc.h>
#include <machine/sysarch.h>

#define ioport_read(port)         inb(port)
#define ioport_write(port, val)   outb(port, val)
#define ioport_enable(port, num)  i386_set_ioperm(port, num, 1)
#define ioport_disable(port, num) i386_set_ioperm(port, num, 0)

#else

/* Direct I/O port access not supported - ppdev/ppi kernel driver
   required for parallel port support to work at all.  Only likely to
   work on PC-style parallel ports (all signals implemented) anyway.

   The only lines believed to be implemented in all parallel ports are:
	D0-D6 outputs	(long long ago I heard of some non-PC machine with
			D7 hardwired to GND - don't remember what it was)
	BUSY input

   So far, only the dt006 interface happens to use a subset of the above.

	STROBE output might be pulsed by hardware and not be writable
	ACK input might only trigger an interrupt and not be readable

   Future designers of these "dongles" might want to keep this in mind.
 */

#define ioport_read(port)         (0xFF)
#define ioport_write(port, val)
#define ioport_enable(port, num)  (-1)
#define ioport_disable(port, num) (0)

#endif

#endif /* NO_DIRECT_IO */

#include <unistd.h>
#include <signal.h>
#include "timeradd.h"

#include <sys/ioctl.h>
#include <fcntl.h>

#include "parport.h"

/* These should work on any architecture, not just i386.  */
#if defined(__linux__)

#include "ppdev.h"

#define par_claim(fd)            ioctl(fd, PPCLAIM, 0)
#define par_read_status(fd, ptr) ioctl(fd, PPRSTATUS, ptr)
#define par_write_data(fd, ptr)  ioctl(fd, PPWDATA, ptr)
#define par_write_ctrl(fd, ptr)  ioctl(fd, PPWCONTROL, ptr)
#define par_set_dir(fd, ptr)     ioctl(fd, PPDATADIR, ptr)
#define par_release(fd)          ioctl(fd, PPRELEASE, 0)

#elif defined(__FreeBSD__)

#include </sys/dev/ppbus/ppi.h>

#define par_claim(fd)            (0)
#define par_read_status(fd, ptr) ioctl(fd, PPIGSTATUS, ptr)
#define par_write_data(fd, ptr)  ioctl(fd, PPISDATA, ptr)
#define par_write_ctrl(fd, ptr)  ioctl(fd, PPISCTRL, ptr)
/* par_set_dir not defined, par_write_ctrl used instead */
#define par_release(fd)          (0)

#else

/* Dummy defines if ppdev/ppi not supported by the kernel.  */

#define par_claim(fd)            (-1)
#define par_read_status(fd, ptr)
#define par_write_data(fd, ptr)
#define par_write_ctrl(fd, ptr)
#define par_release(fd)          

#endif

#include "Global.h"
#include "Error.h"
#include "DAPA.h"
#include "Avr.h"

/* Parallel Port Base Address
*/
#define IOBASE parport_base
#define IOSIZE 3

/* FIXME: rewrite using tables to define new interface types.

   For each of the logical outputs (SCK, MOSI, RESET, ENA1, ENA2,
   power, XTAL1) there should be two bit masks that define which
   physical bits (from the parallel port output data or control
   registers, or serial port DTR/RTS/TXD) are affected, and if
   they should be inverted.  More than one output may be changed.
   For each of the inputs (MISO, maybe TEST?), define which bit
   (only one, from parallel port status or CTS/DCD/DSR/RI) should
   be tested and if it should be inverted.
   One struct as described above should be initialized for each
   of the supported hardware interfaces.
 */

/* Alex's Direct Avr Parallel Access 
*/
#define DAPA_SCK    PARPORT_CONTROL_STROBE	/* base + 2 */
#define DAPA_RESET  PARPORT_CONTROL_INIT	/* base + 2 */
#define DAPA_DIN    PARPORT_STATUS_BUSY		/* base + 1 */
#define DAPA_DOUT   0x1		/* base */

/* STK200 Direct Parallel Access 
*/
#define STK2_TEST1  0x01	/* D0 (base) - may be connected to POUT input */
#define STK2_TEST2  0x02	/* D1 (base) - may be connected to BUSY input */
#define STK2_ENA1   0x04    	/* D2 (base) - ENABLE# for RESET#, MISO */
#define STK2_ENA2   0x08    	/* D3 (base) - ENABLE# for SCK, MOSI, LED# */
#define STK2_SCK    0x10    	/* D4 (base) - SCK */
#define STK2_DOUT   0x20    	/* D5 (base) - MOSI */
#define STK2_LED    0x40	/* D6 (base) - LED# (optional) */
#define STK2_RESET  0x80    	/* D7 (base) - RESET# */
#define STK2_DIN    PARPORT_STATUS_ACK    	/* ACK (base + 1) - MISO */

/* Altera Byte Blaster Port Configuration
*/
#define ABB_EN      PARPORT_CONTROL_AUTOFD	/* low active */
#define ABB_LPAD    0x80	/* D7: loop back throught enable auto-detect */
#define ABB_SCK	    0x01	/* D0: TCK */
#define ABB_RESET   0x02	/* D1: TMS */
#define ABB_DOUT    0x40	/* D6: TDI */
#define ABB_DIN	    PARPORT_STATUS_BUSY	/* BUSY: TDO */
/* D5 (pin 7) connected to ACK (pin 10) directly */
/* D7 (pin 9) connected to POUT (pin 12) via 74HC244 buffer */
/* optional modification for AVREAL: D3 (pin 5) = XTAL1 */
#define ABB_XTAL1   0x08

/* "Atmel AVR ISP" cable (?)
 */
#define AISP_TSTOUT 0x08	/* D3 (base) - dongle test output */
#define AISP_SCK    0x10	/* D4 (base) - SCK */
#define AISP_DOUT   0x20	/* D5 (base) - MOSI */
#define AISP_ENA    0x40	/* D6 (base) - ENABLE# for MISO, MOSI, SCK */
#define AISP_RESET  0x80	/* D7 (base) - RESET# */
#define AISP_DIN    PARPORT_STATUS_ACK /* ACK (base + 1) - MISO */
/* BUSY and POUT used as inputs to test for the dongle */

/* Yet another AVR ISP cable from http://www.bsdhome.com/avrprog/
 */
#define BSD_POWER   0x0F	/* D0-D3 (base) - power */
#define BSD_ENA     0x10	/* D4 (base) - ENABLE# */
#define BSD_RESET   0x20	/* D5 (base) - RESET# */
#define BSD_SCK     0x40	/* D6 (base) - SCK */
#define BSD_DOUT    0x80	/* D7 (base) - MOSI */
#define BSD_DIN     PARPORT_STATUS_ACK /* ACK (base + 1) - MISO */
/* optional status LEDs, active low, not yet supported (base + 2) */
#define BSD_LED_ERR PARPORT_CONTROL_STROBE  /* error */
#define BSD_LED_RDY PARPORT_CONTROL_AUTOFD  /* ready */
#define BSD_LED_PGM PARPORT_CONTROL_INIT    /* programming */
#define BSD_LED_VFY PARPORT_CONTROL_SELECT  /* verifying */

/*
   FBPRG - http://ln.com.ua/~real/avreal/adapters.html
*/
#define FBPRG_POW    0x07	/* D0,D1,D2 (base) - power supply (XXX D7 too?) */
#define FBPRG_XTAL1  0x08	/* D3 (base) (not supported) */
#define FBPRG_RESET  0x10	/* D4 (base) */
#define FBPRG_DOUT   0x20	/* D5 (base) */
#define FBPRG_SCK    0x40	/* D6 (base) */
#define FBPRG_DIN    PARPORT_STATUS_ACK /* ACK (base + 1) - MISO */

/* DT006/Sample Electronics Parallel Cable
   http://www.dontronics.com/dt006.html
*/
/* all at base, except for DT006_DIN at base + 1 */
#define DT006_SCK    0x08
#define DT006_RESET  0x04
#define DT006_DIN    PARPORT_STATUS_BUSY
#define DT006_DOUT   0x01

/* Default value for minimum SCK high/low time in microseconds.  */
#ifndef SCK_DELAY
#define SCK_DELAY 5
#endif

/* Minimum RESET# high time in microseconds.
   Should be enough to charge a capacitor between RESET# and GND
   (it is recommended to use a voltage detector with open collector
   output, and only something like 100 nF for noise immunity).  */
#ifndef RESET_HIGH_TIME
#define RESET_HIGH_TIME 1000
#endif

/* Delay from RESET# low to sending program enable command
   (the datasheet says it must be at least 20 ms).  Also wait time
   for crystal oscillator to start after possible power down mode.  */
#ifndef RESET_LOW_TIME
#define RESET_LOW_TIME 30000
#endif

void
TDAPA::SckDelay()
{
  Delay_usec(t_sck);
}

#ifndef MIN_SLEEP_USEC
#define MIN_SLEEP_USEC 20000
#endif

void
TDAPA::Delay_usec(long t)
{
#if defined(__CYGWIN__)
  if (cygwinp_delay_usec(t)){
    return;
  }
#endif

  struct timeval t1, t2;

  if (t <= 0)
    return;  /* very short delay for slow machines */
  gettimeofday(&t1, NULL);
  if (t > MIN_SLEEP_USEC)
    usleep(t - MIN_SLEEP_USEC);
  /* loop for the remaining time */
  t2.tv_sec = t / 1000000UL;
  t2.tv_usec = t % 1000000UL;
  timeradd(&t1, &t2, &t1);
  do {
    gettimeofday(&t2, NULL);
  } while (timercmp(&t2, &t1, <));
}

void
TDAPA::ParportSetDir(int dir)
{
  if (dir)
    par_ctrl |= PARPORT_CONTROL_DIRECTION;
  else
    par_ctrl &= ~PARPORT_CONTROL_DIRECTION;

  if (ppdev_fd != -1) {
#ifdef par_set_dir
    par_set_dir(ppdev_fd, &dir);
#else
    par_write_ctrl(ppdev_fd, &par_ctrl);
#endif
  } else
    ioport_write(IOBASE+2, par_ctrl);
}

void
TDAPA::ParportWriteCtrl()
{
  if (ppdev_fd != -1)
    par_write_ctrl(ppdev_fd, &par_ctrl);
  else
    ioport_write(IOBASE+2, par_ctrl);
}

void
TDAPA::ParportWriteData()
{
  if (ppdev_fd != -1)
    par_write_data(ppdev_fd, &par_data);
  else
    ioport_write(IOBASE, par_data);
}

void
TDAPA::ParportReadStatus()
{
  if (ppdev_fd != -1)
    par_read_status(ppdev_fd, &par_status);
  else
    par_status = ioport_read(IOBASE+1);
}

void
TDAPA::SerialReadCtrl()
{
#ifdef TIOCMGET
  ioctl(ppdev_fd, TIOCMGET, &ser_ctrl);
#else
  ser_ctrl = 0;
#endif
}

void
TDAPA::SerialWriteCtrl()
{
#ifdef TIOCMGET
  ioctl(ppdev_fd, TIOCMSET, &ser_ctrl);
#endif
}

void
TDAPA::OutReset(int b)
{
  switch (pa_type) {
  case PAT_DAPA:
  case PAT_DAPA_2:
    if (b) par_ctrl |= DAPA_RESET; else par_ctrl &= ~DAPA_RESET;
    ParportWriteCtrl();
    break;

  case PAT_STK200:
    if (b) par_data |= STK2_RESET; else par_data &= ~STK2_RESET;
    ParportWriteData();
    break;

  case PAT_ABB:
    if (b) par_data |= ABB_RESET; else par_data &= ~ABB_RESET;
    ParportWriteData();
    break;

  case PAT_AVRISP:
    if (b) par_data |= AISP_RESET; else par_data &= ~AISP_RESET;
    ParportWriteData();
    break;

  case PAT_BSD:
    if (b) par_data |= BSD_RESET; else par_data &= BSD_RESET;
    ParportWriteData();
    break;

  case PAT_FBPRG:
    if (b) par_data |= FBPRG_RESET; else par_data &= ~FBPRG_RESET;
    ParportWriteData();
    break;

  case PAT_DT006:
    if (b) par_data |= DT006_RESET; else par_data &= ~DT006_RESET;
    ParportWriteData();
    break;

#ifdef TIOCMGET
  case PAT_DASA:
    SerialReadCtrl();
    if (b) ser_ctrl |= TIOCM_RTS; else ser_ctrl &= ~TIOCM_RTS;
    SerialWriteCtrl();
    break;

  case PAT_DASA2:
    ioctl(ppdev_fd, b ? TIOCSBRK : TIOCCBRK, 0);
    break;
#else
  case PAT_DASA:
  case PAT_DASA2:
    break;
#endif /* TIOCMGET */
  }
  Delay_usec(b ? RESET_HIGH_TIME : RESET_LOW_TIME);
}

void
TDAPA::OutSck(int b)
{
  switch (pa_type) {
  case PAT_DAPA:
  case PAT_DAPA_2:
    if (b) par_ctrl &= ~DAPA_SCK; else par_ctrl |= DAPA_SCK;
    ParportWriteCtrl();
    break;

  case PAT_STK200:
    if (b) par_data |= STK2_SCK; else par_data &= ~STK2_SCK;
    ParportWriteData();
    break;

  case PAT_ABB:
    if (b) par_data |= ABB_SCK; else par_data &= ~ABB_SCK;
    ParportWriteData();
    break;

  case PAT_AVRISP:
    if (b) par_data |= AISP_SCK; else par_data &= ~AISP_SCK;
    ParportWriteData();
    break;

  case PAT_BSD:
    if (b) par_data |= BSD_SCK; else par_data &= ~BSD_SCK;
    ParportWriteData();
    break;

  case PAT_FBPRG:
    if (b) par_data |= FBPRG_SCK; else par_data &= ~FBPRG_SCK;
    ParportWriteData();
    break;

  case PAT_DT006:
    if (b) par_data |= DT006_SCK; else par_data &= ~DT006_SCK;
    ParportWriteData();
    break;

#ifdef TIOCMGET
  case PAT_DASA:
    SerialReadCtrl();
    if (b) ser_ctrl |= TIOCM_DTR; else ser_ctrl &= ~TIOCM_DTR;
    SerialWriteCtrl();
    break;

  case PAT_DASA2:
    SerialReadCtrl();
    if (b) ser_ctrl |= TIOCM_RTS; else ser_ctrl &= ~TIOCM_RTS;
    SerialWriteCtrl();
    break;
#else
  case PAT_DASA:
  case PAT_DASA2:
    break;
#endif /* TIOCMGET */
  }
}


void
TDAPA::OutEnaReset(int b)
{
  bool no_ps2_hack = GetCmdParam("-dno-ps2-hack", false);
  switch (pa_type) {
  case PAT_DAPA:
  case PAT_DAPA_2:
  case PAT_FBPRG:
  case PAT_DT006:
    if (b) {
      ParportSetDir(0);
    } else if (!no_ps2_hack) {
      /* No special enable line on these interfaces, for PAT_DAPA
         this only disables the data line (MOSI) and not SCK.  */
      ParportSetDir(1);
    }
    break;

  case PAT_STK200:
    if (b) {
      /* Make sure outputs are enabled.  */
      ParportSetDir(0);
      SckDelay();
      par_data &= ~STK2_ENA1;
      ParportWriteData();
    } else {
      par_data |= STK2_ENA1;
      ParportWriteData();
      if (!no_ps2_hack) {
        /* Experimental: disable outputs (PS/2 parallel port), for cheap
	   STK200-like cable without the '244.  Should work with the real
           STK200 too (disabled outputs should still have pull-up resistors,
	   ENA1 and ENA2 are high, and the '244 remains disabled).
	   This way the SPI pins can be used by the application too.
	   Please report if it doesn't work on some parallel ports.  */
	SckDelay();
	ParportSetDir(1);
      }
    }
    break;

  case PAT_ABB:
    if (b) {
      ParportSetDir(0);
      par_ctrl |= ABB_EN;
      ParportWriteCtrl();
    } else {
      par_ctrl &= ~ABB_EN;
      ParportWriteCtrl();
      if (!no_ps2_hack) {
	SckDelay();
	ParportSetDir(1);
      }
    }
    break;

  case PAT_AVRISP:
    if (b) {
      ParportSetDir(0);
      SckDelay();
      par_data &= ~AISP_ENA;
      ParportWriteData();
    } else {
      par_data |= AISP_ENA;
      ParportWriteData();
      if (!no_ps2_hack) {
	SckDelay();
	ParportSetDir(1);
      }
    }
    break;

  case PAT_BSD:
    if (b) {
      ParportSetDir(0);
      SckDelay();
      par_data &= ~BSD_ENA;
      ParportWriteData();
    } else {
      par_data |= BSD_ENA;
      ParportWriteData();
      if (!no_ps2_hack) {
	SckDelay();
	ParportSetDir(1);
      }
    }
    break;

  case PAT_DASA:
  case PAT_DASA2:
    break;
  }
}

void
TDAPA::OutEnaSck(int b)
{
  switch (pa_type) {
  case PAT_STK200:
    if (b)
      par_data &= ~(STK2_ENA2 | STK2_LED);
    else
      par_data |= (STK2_ENA2 | STK2_LED);
    ParportWriteData();
    break;

  case PAT_DAPA:
  case PAT_DAPA_2:
  case PAT_ABB:
  case PAT_AVRISP:
  case PAT_BSD:
  case PAT_FBPRG:
  case PAT_DT006:
  case PAT_DASA:
  case PAT_DASA2:
    /* no separate enable for SCK nad MOSI */
    break;
  }
}

void
TDAPA::PulseSck()
{
  SckDelay();
  OutSck(1);
  SckDelay();
  OutSck(0);
}

void
TDAPA::PulseReset()
{
	printf("pulse\n");
  /* necessary delays already included in these methods */
  OutReset(1);
 Delay_usec(1000); 
  OutReset(0);
}

void
TDAPA::OutData(int b)
{
  switch (pa_type) {
  case PAT_DAPA:
    if (b) par_data |= DAPA_DOUT; else par_data &= ~DAPA_DOUT;
    par_data &= ~0x6; //0x6
    par_data |= 0x0; //0x6
    ParportWriteData();
    break;

  case PAT_DAPA_2:
    if (b) par_data |= DAPA_DOUT; else par_data &= ~DAPA_DOUT;
    par_data &= ~0x6; //0x6
    par_data |= 0x4; //0x6
    ParportWriteData();
    break;

  case PAT_STK200:
    if (b) par_data |= STK2_DOUT; else par_data &= ~STK2_DOUT;
    ParportWriteData();
    break;

  case PAT_ABB:
    if (b) par_data |= ABB_DOUT; else par_data &= ~ABB_DOUT;
    ParportWriteData();
    break;

  case PAT_AVRISP:
    if (b) par_data |= AISP_DOUT; else par_data &= ~AISP_DOUT;
    ParportWriteData();
    break;

  case PAT_BSD:
    if (b) par_data |= BSD_DOUT; else par_data &= ~BSD_DOUT;
    ParportWriteData();
    break;

  case PAT_FBPRG:
    if (b) par_data |= FBPRG_DOUT; else par_data &= ~FBPRG_DOUT;
    ParportWriteData();
    break;

  case PAT_DT006:
    if (b) par_data |= DT006_DOUT; else par_data &= ~DT006_DOUT;
    ParportWriteData();
    break;

#ifdef TIOCMGET
  case PAT_DASA:
    ioctl(ppdev_fd, b ? TIOCSBRK : TIOCCBRK, 0);
    break;

  case PAT_DASA2:
    SerialReadCtrl();
    if (b) ser_ctrl |= TIOCM_DTR; else ser_ctrl &= ~TIOCM_DTR;
    SerialWriteCtrl();
    break;
#else
  case PAT_DASA:
  case PAT_DASA2:
    break;

#endif /* TIOCMGET */
  }
}

int
TDAPA::InData()
{
#ifdef TIOCMGET
  switch (pa_type) {
  case PAT_DASA:
  case PAT_DASA2:
    SerialReadCtrl();
    return (ser_ctrl & TIOCM_CTS);
  default:
    break;
  }
#endif /* TIOCMGET */
  ParportReadStatus();
  switch (pa_type) {
  case PAT_DAPA:
  case PAT_DAPA_2:
    return (~par_status & DAPA_DIN);
  case PAT_STK200:
    return (par_status & STK2_DIN);
  case PAT_ABB:
    return (~par_status & ABB_DIN);
  case PAT_AVRISP:
    return (par_status & AISP_DIN);
  case PAT_BSD:
    return (par_status & BSD_DIN);
  case PAT_FBPRG:
    return (par_status & FBPRG_DIN);
  case PAT_DT006:
    return (~par_status & DT006_DIN);
  case PAT_DASA:
  case PAT_DASA2:
    break;
  }
  return 0;
}

void
TDAPA::Init()
{
  /* data=1, reset=0, sck=0 */
  switch (pa_type) {
  case PAT_DAPA:
    par_ctrl = DAPA_SCK;
    par_data = 0xFF;
    par_data &= ~0x6; //0x6
    par_data |= 0x0; //0x6
    break;
  case PAT_DAPA_2:
    par_ctrl = DAPA_SCK;
    par_data = 0xFF;
    par_data &= ~0x6; //0x6
    par_data |= 0x4; //0x6
    break;

  case PAT_STK200:
    par_ctrl = 0;
    par_data = 0xFF & ~(STK2_ENA1 | STK2_SCK);
    break;

  case PAT_ABB:
    par_ctrl = ABB_EN;
    par_data = 0xFF & ~ABB_SCK;
    break;

  case PAT_AVRISP:
    par_ctrl = 0;
    par_data = 0xFF & ~(AISP_ENA | AISP_SCK);
    break;

  case PAT_BSD:
    par_ctrl = 0;
    par_data = 0xFF & ~(BSD_ENA | BSD_SCK);
    break;

  case PAT_FBPRG:
    par_ctrl = 0;
    par_data = FBPRG_POW | FBPRG_RESET;
    break;

  case PAT_DT006:
    par_ctrl = 0;
    par_data = 0xFF;
    break;

  case PAT_DASA:
  case PAT_DASA2:
    break;
  }

  if (!pa_type_is_serial) {
    ParportWriteCtrl();
    ParportWriteData();
    SckDelay();
    ParportReadStatus();
  }

  OutEnaReset(1);
  OutReset(0);
  OutEnaSck(1);
  OutSck(0);
  /* Wait 100 ms as recommended for ATmega163 (SCK not low on power up).  */
  Delay_usec(100000);
  PulseReset();
}

int
TDAPA::SendRecv(int b)
{
  unsigned int mask, received=0;

  for (mask = 0x80; mask; mask >>= 1) {
     OutData(b & mask);
     SckDelay();
     if (InData())
       received |= mask;
     OutSck(1);
     SckDelay();
     OutSck(0);
  }
  return received;
}

int
TDAPA::Send (unsigned char* queue, int queueSize, int rec_queueSize=-1){
  unsigned char *p = queue, ch;
  int i = queueSize;
  
  if (rec_queueSize==-1){rec_queueSize = queueSize;}
#ifdef DEBUG
  printf ("send(recv): ");
#endif
  while (i--){
#ifdef DEBUG
    printf ("%02X(", (unsigned int)*p);
#endif    
    ch = SendRecv(*p);
#ifdef DEBUG    
    printf ("%02X) ", (unsigned int)ch);
#endif    
    *p++ = ch;
  }
#ifdef DEBUG  
  printf ("\n");
#endif  
  return queueSize;
}


TDAPA::TDAPA(): 
  parport_base(0x378), ppdev_fd(-1)
{
  const char *val;
  const char *ppdev_name = NULL;

  /* Enable Parallel Port */
  val = GetCmdParam("-dprog");
  if (val && strcmp(val, "dapa") == 0)
    pa_type = PAT_DAPA;
  else if (val && strcmp(val, "dapa_2") == 0)
    pa_type = PAT_DAPA_2;
  else if (val && strcmp(val, "stk200") == 0)
    pa_type = PAT_STK200;
  else if (val && strcmp(val, "abb") == 0)
    pa_type = PAT_ABB;
  else if (val && strcmp(val, "avrisp") == 0)
    pa_type = PAT_AVRISP;
  else if (val && strcmp(val, "bsd") == 0)
    pa_type = PAT_BSD;
  else if (val && strcmp(val, "fbprg") == 0)
    pa_type = PAT_FBPRG;
  else if (val && strcmp(val, "dt006") == 0)
    pa_type = PAT_DT006;
  else if (val && strcmp(val, "dasa") == 0)
    pa_type = PAT_DASA;
  else if (val && strcmp(val, "dasa2") == 0)
    pa_type = PAT_DASA2;
  else {
    throw Error_Device("Direct Parallel Access not defined.");
  }
  pa_type_is_serial = (pa_type == PAT_DASA || pa_type == PAT_DASA2);
  /* Parse Command Line Switches */
#ifndef NO_DIRECT_IO
  if ((val = GetCmdParam("-dlpt")) != NULL) {
    if (!strcmp(val, "1")){parport_base = 0x378;}
    else if (!strcmp(val, "2")){parport_base = 0x278;}
    else if (!strcmp(val, "3")){parport_base = 0x3bc;}    
    else if (*val != '/') { parport_base = strtol(val, NULL, 0); }
    else { ppdev_name = val; }
  }
  if (!ppdev_name && !pa_type_is_serial) {
    if (parport_base!=0x278 && parport_base!=0x378 && parport_base!=0x3bc) {
      /* TODO: option to override this if you really know
	 what you're doing (only if running as root).  */
      throw Error_Device("Bad device address.");
    }
    if (ioport_enable(IOBASE, IOSIZE) != 0) {
      perror("ioperm");
      throw Error_Device("Failed to get direct I/O port access.");
    }
  }
#endif

  /* Drop privileges (if installed setuid root - NOT RECOMMENDED).  */
  setgid(getgid());
  setuid(getuid());

#ifdef NO_DIRECT_IO
  if ((val = GetCmdParam("-dlpt")) != NULL) {
    ppdev_name = val;
  } else {
    ppdev_name = "/dev/parport0";
  }
#endif

  if (ppdev_name) {
    if (pa_type_is_serial) {
      ppdev_fd = open(ppdev_name, O_RDWR | O_NOCTTY | O_NONBLOCK);
      if (ppdev_fd != -1) {
	struct termios pmode;

	tcgetattr(ppdev_fd, &pmode);
	saved_modes = pmode;

	cfmakeraw(&pmode);
	pmode.c_iflag &= ~(INPCK | IXOFF | IXON);
	pmode.c_cflag &= ~(HUPCL | CSTOPB | CRTSCTS);
	pmode.c_cflag |= (CLOCAL | CREAD);
	pmode.c_cc [VMIN] = 1;
	pmode.c_cc [VTIME] = 0;

	tcsetattr(ppdev_fd, TCSANOW, &pmode);

	/* Clear O_NONBLOCK flag.  */
	int flags = fcntl(ppdev_fd, F_GETFL, 0);
	if (flags == -1) { throw Error_C(); }
	flags &= ~O_NONBLOCK;
	if (fcntl(ppdev_fd, F_SETFL, flags) == -1) { throw Error_C(); }
      }
    } else {
      ppdev_fd = open(ppdev_name, O_RDWR, 0);
    }
    if (ppdev_fd == -1) {
      perror(ppdev_name);
      throw Error_Device("Failed to open ppdev.");
    }
    if (!pa_type_is_serial && par_claim(ppdev_fd) != 0) {
      perror("ioctl PPCLAIM");
      close(ppdev_fd);
      ppdev_fd = -1;
      throw Error_Device("Failed to claim ppdev.");
    }
  }
  t_sck = SCK_DELAY;
  if (pa_type_is_serial)
    t_sck *= 3;  /* more delay for slow RS232 drivers */
  val = GetCmdParam("-dt_sck");
  if (val)
    t_sck = strtol(val, NULL, 0);
  Init();
}

TDAPA::~TDAPA()
{
  OutData(1); SckDelay();
  OutSck(1); SckDelay();
  OutEnaSck(0);
  OutReset(1);
  OutEnaReset(0);

  if (ppdev_fd != -1) {
    if (pa_type_is_serial)
      tcsetattr(ppdev_fd, TCSADRAIN, &saved_modes);
    else
      par_release(ppdev_fd);
    close(ppdev_fd);
    ppdev_fd = -1;
  } else
    (void) ioport_disable(IOBASE, IOSIZE);
}

#endif
/* eof */
