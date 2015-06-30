/*
 *  Hacked version of slip.h
 *
 *  Andrew Christian
 *  18 January 2005
 *
 *
 * slip.h	Define the SLIP device driver interface and constants.
 *
 * NOTE:	THIS FILE WILL BE MOVED TO THE LINUX INCLUDE DIRECTORY
 *		AS SOON AS POSSIBLE!
 *
 * Version:	@(#)slip.h	1.2.0	03/28/93
 *
 * Fixes:
 *		Alan Cox	: 	Added slip mtu field.
 *		Matt Dillon	:	Printable slip (borrowed from net2e)
 *		Alan Cox	:	Added SL_SLIP_LOTS
 *	Dmitry Gorodchanin	:	A lot of changes in the 'struct slip'
 *	Dmitry Gorodchanin	:	Added CSLIP statistics.
 *	Stanislav Voronyi	:	Make line checking as created by
 *					Igor Chechik, RELCOM Corp.
 *	Craig Schlenter		:	Fixed #define bug that caused
 *					CSLIP telnets to hang in 1.3.61-6
 *
 * Author:	Fred N. van Kempen, <waltje@uwalt.nl.mugnet.org>
 *
 * Portions of this driver are
 * Copyright 2005 Hewlett-Packard Company
 *
 * Use consistent with the GNU GPL is permitted,
 * provided that this copyright notice is
 * preserved in its entirety in all copies and derived works.
 *
 * HEWLETT-PACKARD COMPANY MAKES NO WARRANTIES, EXPRESSED OR IMPLIED,
 * AS TO THE USEFULNESS OR CORRECTNESS OF THIS CODE OR ITS
 * FITNESS FOR ANY PARTICULAR PURPOSE.
 */

#ifndef _LINUX_SPAN_AP_H
#define _LINUX_SPAN_AP_H

#include <linux/version.h>
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,32)
#include <generated/autoconf.h>
#define SET_MODULE_OWNER(dev) do { } while (0)

//#ifdef KERNEL_2_6_24_OR_NEWER

#elif LINUX_VERSION_CODE > KERNEL_VERSION(2,6,23)
#define SET_MODULE_OWNER(dev) do { } while (0)
#include <linux/autoconf.h>

//#elif defined KERNEL_2_6_19_OR_NEWER

#elif LINUX_VERSION_CODE > KERNEL_VERSION(2,6,18)
#include <linux/autoconf.h>
#else
#include <linux/config.h>
#endif
/* SPAN_AP configuration. */
#define SPAN_NRUNIT	8		/* MAX number of SPAN_AP channels;
					   This can be overridden with
					   insmod -ospan_ap_maxdev=nnn	*/
#define SPAN_MTU	117             /* We delete 10 bytes to leave room for LLH and 802.15.4 stuff*/

/* TELOS_AP protocol characters.
 *
 * Each packet has the form FRAME DATA+ FRAME where there are no more than 127 data bytes.
 * Data packet values of FRAME and ESCAPE_BYTE are escaped by being replaced by ESCAPE_BYTE, x^0x20
 *
 * FRAME       = 0x7e
 * ESCAPE_BYTE = 0x7d
 */

#define FRAME           0x7e
#define ESCAPE_BYTE     0x7d

#define ESCAPE_FRAME    (FRAME ^ 0x20)
#define ESCAPE_ESCAPE   (ESCAPE_BYTE ^ 0x20)

/*
 * Communication between the Span device and the Linux device is framed
 * by commands, data, and messages
 */

#define SPAN_COMMAND                1    // Include one byte command type + extra data
#define SPAN_COMMAND_REQUEST_TABLE  1

/*
 * Data messages, sent either way, include;
 * 
 *  SPAN_DATA            (1 byte)
 *  IP Packet
 */

#define SPAN_RESET                  0
#define SPAN_MESSAGE                1
#define SPAN_DATA                   2    // Include one byte short child address + data
#define SPAN_RESPONSE               3

/* Messages from Span
 *
 *  SPAN_MESSAGE           (1 byte)
 *  SPAN_MESSAGE_type      (1 byte)
 *  Short address           (2 bytes)
 *  Long address            (8 bytes)
 *  Flags                   (1 byte)
 *  IP Address              (4 bytes)
 */

#define SPAN_MESSAGE_ASSOCIATE   1 
#define SPAN_MESSAGE_REASSOCIATE 2
#define SPAN_MESSAGE_STALE       3
#define SPAN_MESSAGE_RELEASED    4
#define SPAN_MESSAGE_ARP         5

#define SPAN_RESPONSE_TABLE 1

struct span_ap {
  int			magic;

  /* Various fields. */
  struct tty_struct	*tty;		/* ptr to TTY structure		*/
  struct net_device	*dev;		/* easy for intr handling	*/
  spinlock_t		lock;

  /* These are pointers to the malloc()ed frame buffers. */
  unsigned char		*rbuff;		/* receiver buffer		*/
  int                   rcount;         /* received chars counter       */
  unsigned char		*xbuff;		/* transmitter buffer		*/
  unsigned char         *xhead;         /* pointer to next byte to XMIT */
  int                   xleft;          /* bytes left in XMIT queue     */

  /* SPAN_AP interface statistics. */
  unsigned long		rx_packets;	/* inbound frames counter	*/
  unsigned long         tx_packets;     /* outbound frames counter      */
  unsigned long		rx_bytes;	/* inbound byte counte		*/
  unsigned long         tx_bytes;       /* outbound byte counter	*/
  unsigned long         rx_errors;      /* Parity, etc. errors          */
  unsigned long         tx_errors;      /* Planned stuff                */
  unsigned long         rx_dropped;     /* No memory for skb            */
  unsigned long         tx_dropped;     /* When MTU change              */
  unsigned long         rx_over_errors; /* Frame bigger then SPAN_AP buf.  */
  /* Detailed SPAN_AP statistics. */

  int			mtu;		/* Our mtu (to spot changes!)   */
  int                   buffsize;       /* Max buffers sizes            */

  unsigned long		flags;		/* Flag values/ mode etc	*/
#define SPANF_INUSE	0		/* Channel in use               */
#define SPANF_ESCAPE	1               /* ESC received                 */
#define SPANF_ERROR	2               /* Parity, etc. error           */
#define SPANF_KEEPTEST	3		/* Keepalive test flag		*/
#define SPANF_OUTWAIT	4		/* is outpacket was flag	*/

  dev_t			line;
  pid_t			pid;

#define SPAN_READ_QUEUE_DEPTH 8
  int                   read_queue_head;
  int                   read_queue_tail;
  struct SpanInform    read_queue[SPAN_READ_QUEUE_DEPTH];
};

#define SPAN_AP_MAGIC 0x5302

#endif	/* _LINUX_SPAN_AP.H */
