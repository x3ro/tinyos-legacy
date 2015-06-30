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

#ifndef _LINUX_TELOS_AP_H
#define _LINUX_TELOS_AP_H

#include <linux/config.h>

/* TELOS_AP configuration. */
#define TELOS_NRUNIT	8		/* MAX number of TELOS_AP channels;
					   This can be overridden with
					   insmod -otelos_ap_maxdev=nnn	*/
#define TELOS_MTU	117             /* We delete 10 bytes to leave room for LLH and 802.15.4 stuff*/

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
 * Communication between the Telos device and the Linux device is framed
 * by commands, data, and messages
 */

#define TELOS_COMMAND                1    // Include one byte command type + extra data
#define TELOS_COMMAND_REQUEST_TABLE  1

/*
 * Data messages, sent either way, include;
 * 
 *  TELOS_DATA            (1 byte)
 *  IP Packet
 */

#define TELOS_RESET                  0
#define TELOS_MESSAGE                1
#define TELOS_DATA                   2    // Include one byte short child address + data
#define TELOS_RESPONSE               3

/* Messages from Telos
 *
 *  TELOS_MESSAGE           (1 byte)
 *  TELOS_MESSAGE_type      (1 byte)
 *  Short address           (2 bytes)
 *  Long address            (8 bytes)
 *  Flags                   (1 byte)
 *  IP Address              (4 bytes)
 */

#define TELOS_MESSAGE_ASSOCIATE   1 
#define TELOS_MESSAGE_REASSOCIATE 2
#define TELOS_MESSAGE_STALE       3
#define TELOS_MESSAGE_RELEASED    4
#define TELOS_MESSAGE_ARP         5

#define TELOS_RESPONSE_TABLE 1

struct telos_ap {
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

  /* TELOS_AP interface statistics. */
  unsigned long		rx_packets;	/* inbound frames counter	*/
  unsigned long         tx_packets;     /* outbound frames counter      */
  unsigned long		rx_bytes;	/* inbound byte counte		*/
  unsigned long         tx_bytes;       /* outbound byte counter	*/
  unsigned long         rx_errors;      /* Parity, etc. errors          */
  unsigned long         tx_errors;      /* Planned stuff                */
  unsigned long         rx_dropped;     /* No memory for skb            */
  unsigned long         tx_dropped;     /* When MTU change              */
  unsigned long         rx_over_errors; /* Frame bigger then TELOS_AP buf.  */
  /* Detailed TELOS_AP statistics. */

  int			mtu;		/* Our mtu (to spot changes!)   */
  int                   buffsize;       /* Max buffers sizes            */

  unsigned long		flags;		/* Flag values/ mode etc	*/
#define TELOSF_INUSE	0		/* Channel in use               */
#define TELOSF_ESCAPE	1               /* ESC received                 */
#define TELOSF_ERROR	2               /* Parity, etc. error           */
#define TELOSF_KEEPTEST	3		/* Keepalive test flag		*/
#define TELOSF_OUTWAIT	4		/* is outpacket was flag	*/

  dev_t			line;
  pid_t			pid;

#define TELOS_READ_QUEUE_DEPTH 8
  int                   read_queue_head;
  int                   read_queue_tail;
  struct TelosInform    read_queue[TELOS_READ_QUEUE_DEPTH];
};

#define TELOS_AP_MAGIC 0x5302

#endif	/* _LINUX_TELOS_AP.H */
