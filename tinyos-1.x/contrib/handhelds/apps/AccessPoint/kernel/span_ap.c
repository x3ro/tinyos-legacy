/*
 *  This is a hacked version of the SLIP driver, modified for use as a 802.15.4
 *  access point.  The basic idea is that a Telos (www.moteiv.com) USB card is
 *  plugged into a standard Linux box and is used as a radio interface device.
 *  The Telos card runs special software that manages the client connections and
 *  sends data packets back to the Linux box alerting it when clients come and
 *  go.  The Telos USB chip (an FTDI BM232) shows up as a well-defined serial 
 *  device - I didn't see any way to easily modify that into a network device
 *  driver because most of the time I need it as regular USB.  Hence a serial line
 *  discipline converter.  Of which SLIP is the canonical simple example.
 *
 *  Andrew Christian
 *  18 January 2005
 *
 * telos moniker updated to span, as shimmer research maintains this code.
 * steve ayer
 * march, 2010
 * 
 * slip.c	This module implements the SLIP protocol for kernel-based
 *		devices like TTY.  It interfaces between a raw TTY, and the
 *		kernel's INET protocol layers.
 *
 * Version:	@(#)slip.c	0.8.3	12/24/94
 *
 * Authors:	Laurence Culhane, <loz@holmes.demon.co.uk>
 *		Fred N. van Kempen, <waltje@uwalt.nl.mugnet.org>
 *
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
 *                   
 */

#define SL_CHECK_TRANSMIT

#include <linux/version.h>
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,32)
#include <generated/autoconf.h>

//#ifdef KERNEL_2_6_24_OR_NEWER
//#elif defined KERNEL_2_6_24_OR_NEWER

//#include <linux/autoconf.h>
//#elif defined KERNEL_2_6_19_OR_NEWER

#elif LINUX_VERSION_CODE > KERNEL_VERSION(2,6,18)
#include <linux/autoconf.h>
#else
#include <linux/config.h>
#endif

#include <linux/module.h>

#include <asm/system.h>
#include <asm/uaccess.h>
#include <asm/bitops.h>
#include <linux/string.h>
#include <linux/mm.h>
#include <linux/interrupt.h>
#include <linux/in.h>
#include <linux/tty.h>
#include <linux/errno.h>
#include <linux/netdevice.h>
#include <linux/etherdevice.h>
#include <linux/skbuff.h>
#include <linux/rtnetlink.h>
#include <linux/if_arp.h>
#include "if_span_ap.h"
#include <linux/init.h>
#include "span_ap.h"
#ifdef CONFIG_INET
#include <linux/ip.h>
#include <linux/tcp.h>
#include <net/slhc_vj.h>
#endif
#include <asm/unaligned.h>

#define SPAN_AP_VERSION	"0.9"

static struct net_device **span_ap_devs;

int span_ap_maxdev = SPAN_NRUNIT;		/* Can be overridden with insmod! */
module_param(span_ap_maxdev, int, S_IRUSR);
//MODULE_PARM(span_ap_maxdev, "i");
MODULE_PARM_DESC(span_ap_maxdev, "Maximum number of span_ap devices");

static int span_ap_esc(unsigned char *p, unsigned char *d, int len);
static void span_ap_unesc(struct span_ap *sl, unsigned char c);

/********************************
*  Buffer administration routines:
*	span_alloc_bufs()
*	span_free_bufs()
*	span_realloc_bufs()
*
* NOTE: span_realloc_bufs != span_free_bufs + span_alloc_bufs, because
*	span_realloc_bufs provides strong atomicity and reallocation
*	on actively running device.
*********************************/

/* 
   Allocate channel buffers.
 */

static int
span_alloc_bufs(struct span_ap *span, int mtu)
{
	int err = -ENOBUFS;
	unsigned long len;
	char * rbuff = NULL;
	char * xbuff = NULL;

	// printk(KERN_WARNING "%s: %p\n", __FUNCTION__, span);

	/*
	 * Allocate the SPAN_AP frame buffers:
	 *
	 * rbuff	Receive buffer.
	 * xbuff	Transmit buffer.
	 * cbuff        Temporary compression buffer.
	 */
	len = mtu * 2;

	/*
	 * allow for arrival of larger UDP packets, even if we say not to
	 * also fixes a bug in which SunOS sends 512-byte packets even with
	 * an MSS of 128
	 */
	if (len < 576 * 2)
		len = 576 * 2;
	rbuff = kmalloc(len + 4, GFP_KERNEL);
	if (rbuff == NULL)
		goto err_exit;
	xbuff = kmalloc(len + 4, GFP_KERNEL);
	if (xbuff == NULL)
		goto err_exit;
	spin_lock_bh(&span->lock);
	if (span->tty == NULL) {
		spin_unlock_bh(&span->lock);
		err = -ENODEV;
		goto err_exit;
	}
	span->mtu	     = mtu;
	span->buffsize = len;
	span->rcount   = 0;
	span->xleft    = 0;
	rbuff = xchg(&span->rbuff, rbuff);
	xbuff = xchg(&span->xbuff, xbuff);
	spin_unlock_bh(&span->lock);
	err = 0;

	/* Cleanup */
err_exit:
	if (xbuff)
		kfree(xbuff);
	if (rbuff)
		kfree(rbuff);
	return err;
}

/* Free a SPAN_AP channel buffers. */
static void
span_free_bufs(struct span_ap *span)
{
	void * tmp;

	// printk(KERN_WARNING "%s: %p\n", __FUNCTION__, span);

	/* Free all SPAN_AP frame buffers. */
	if ((tmp = xchg(&span->rbuff, NULL)) != NULL)
		kfree(tmp);
	if ((tmp = xchg(&span->xbuff, NULL)) != NULL)
		kfree(tmp);
}

/* 
   Reallocate span_ap channel buffers.
 */

static int span_realloc_bufs(struct span_ap *span, int mtu)
{
	int err = 0;
	struct net_device *dev = span->dev;
	unsigned char *xbuff, *rbuff;
	int len = mtu * 2;

	// printk(KERN_WARNING "%s: %p\n", __FUNCTION__, span);
/*
 * allow for arrival of larger UDP packets, even if we say not to
 * also fixes a bug in which SunOS sends 512-byte packets even with
 * an MSS of 128
 */
	if (len < 576 * 2)
		len = 576 * 2;

	xbuff = (unsigned char *) kmalloc (len + 4, GFP_ATOMIC);
	rbuff = (unsigned char *) kmalloc (len + 4, GFP_ATOMIC);
	if (xbuff == NULL || rbuff == NULL)  {
		if (mtu >= span->mtu) {
			printk(KERN_WARNING "%s: unable to grow span_ap buffers, MTU change cancelled.\n",
			       dev->name);
			err = -ENOBUFS;
		}
		goto done;
	}

	spin_lock_bh(&span->lock);

	err = -ENODEV;
	if (span->tty == NULL)
		goto done_on_bh;

	xbuff    = xchg(&span->xbuff, xbuff);
	rbuff    = xchg(&span->rbuff, rbuff);
	if (span->xleft)  {
		if (span->xleft <= len)  {
			memcpy(span->xbuff, span->xhead, span->xleft);
		} else  {
			span->xleft = 0;
			span->tx_dropped++;
		}
	}
	span->xhead = span->xbuff;

	if (span->rcount)  {
		if (span->rcount <= len) {
			memcpy(span->rbuff, rbuff, span->rcount);
		} else  {
			span->rcount = 0;
			span->rx_over_errors++;
			set_bit(SPANF_ERROR, &span->flags);
		}
	}
	span->mtu      = mtu;
	dev->mtu      = mtu;
	span->buffsize = len;
	err = 0;

done_on_bh:
	spin_unlock_bh(&span->lock);

done:
	if (xbuff)
		kfree(xbuff);
	if (rbuff)
		kfree(rbuff);
	return err;
}


/* Set the "sending" flag.  This must be atomic hence the set_bit. */
static inline void
span_lock(struct span_ap *span)
{
	// printk(KERN_WARNING "%s: %p\n", __FUNCTION__, span);
	netif_stop_queue(span->dev);
}


/* Clear the "sending" flag.  This must be atomic, hence the ASM. */
static inline void
span_unlock(struct span_ap *span)
{
	// printk(KERN_WARNING "%s: %p\n", __FUNCTION__, span);
	netif_wake_queue(span->dev);
}

/* Send one completely decapsulated IP datagram to the IP layer. */
/*
  Well, technically, this could be control protocol.
  We only call this if there are at least two bytes of data available.

  Structure of the RESET message:

  Byte        Value
  0           0  (indicates an INFORM, 2 = data)
  1-4         IP address
  5-12        long address (8 bytes)
  13-14       pan_id (network byte order)
  15-16       frequency
  17+         ssid (null terminated)

  All other messages take the form:

  Byte        Value
   
  0           1  (indicates an INFORM, 2 = data)
  1-4         IP address
  5-12        long address (8 bytes)
  13-14       short address (MSB first)
  15          event (1=associate, 2=reassociate, ...)
  16          flag byte
 */

static void
span_ap_add_message(struct span_ap *span)
{
	struct SpanInform *si;
	int n = (span->read_queue_head + 1) % SPAN_READ_QUEUE_DEPTH;

	if ( n == span->read_queue_tail ) {
		printk("Span dropped message from client\n");
		return;
	}

	si = span->read_queue + span->read_queue_head;
	memset( si, 0, sizeof(*si));

	memcpy( &si->ip, span->rbuff+1, 4 );
	memcpy( &si->l_addr, span->rbuff+5, 8 );
	memcpy( &si->s_addr, span->rbuff+13, 2 );
	if ( span->rbuff[0] == 0 ) {
		memcpy( &si->frequency, span->rbuff+15, 2 );
		strncpy( si->ssid, span->rbuff+17, 32 );
	}
	else {
		si->event = span->rbuff[15];
		si->flags = span->rbuff[16];
	}
		
	span->read_queue_head = n;
	wake_up_interruptible(&span->tty->read_wait);
}

static void
span_bump(struct span_ap *span)
{
	struct sk_buff *skb;
	int count;

//	printk(KERN_WARNING "%s: %p\n", __FUNCTION__, span);
	count = span->rcount;
	span->rx_bytes+=count;
	
	switch (span->rbuff[0]) {
	case SPAN_RESET:
//		printk("Span received reset message length %d\n", count );
		span_ap_add_message( span );
		break;

	case SPAN_MESSAGE:
//		printk("Span adding message length %d type %d\n", count, span->rbuff[15]);
		span_ap_add_message( span );
		break;
		
	case SPAN_DATA:
		// Encapsulated IP data packet
//		printk("Span DATA packet\n");
		skb = dev_alloc_skb(count);
		if (skb == NULL)  {
			printk(KERN_WARNING "%s: memory squeeze, dropping packet.\n", span->dev->name);
			span->rx_dropped++;
			return;
		}
		skb->dev = span->dev;
		memcpy(skb_put(skb,count - 1), span->rbuff + 1, count - 1);

#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,21)		
		skb->mac_header=skb->data;
#else		
		skb->mac.raw=skb->data;
#endif
		skb->protocol=htons(ETH_P_IP);
		netif_rx(skb);
		break;

	case SPAN_RESPONSE:
		// Response to a request
		break;
	}

	span->dev->last_rx = jiffies;
	span->rx_packets++;
}

/* Encapsulate one IP datagram and stuff into a TTY queue. */
static void
span_encaps(struct span_ap *span, unsigned char *icp, int len)
{
	unsigned char *p;
	int actual, count;

	// printk(KERN_WARNING "%s: %p\n", __FUNCTION__, span);
	if (len > span->mtu) {		/* Sigh, shouldn't occur BUT ... */
		printk(KERN_WARNING "%s: truncating oversized transmit packet!\n", span->dev->name);
		span->tx_dropped++;
		span_unlock(span);
		return;
	}

	p = icp;
	count = span_ap_esc(p, (unsigned char *) span->xbuff, len);

	/* Order of next two lines is *very* important.
	 * When we are sending a little amount of data,
	 * the transfer may be completed inside driver.write()
	 * routine, because it's running with interrupts enabled.
	 * In this case we *never* got WRITE_WAKEUP event,
	 * if we did not request it before write operation.
	 *       14 Oct 1994  Dmitry Gorodchanin.
	 */
	//	span->tty->flags |= (1 << TTY_DO_WRITE_WAKEUP);
	set_bit(TTY_DO_WRITE_WAKEUP, &span->tty->flags);
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,25)
	actual = span->tty->driver->ops->write(span->tty, span->xbuff, count);
#elif LINUX_VERSION_CODE > KERNEL_VERSION(2,6,8)
        actual = span->tty->driver->write(span->tty, span->xbuff, count);
#else
	actual = span->tty->driver->write(span->tty, 0, span->xbuff, count);
#endif
	span->xleft = count - actual;
	span->xhead = span->xbuff + actual;
}

/*
 * Called by the driver when there's room for more data.  If we have
 * more packets to send, we send them here.
 */
static void 
span_ap_write_wakeup(struct tty_struct *tty)
{
	int actual;
	struct span_ap *span = (struct span_ap *) tty->disc_data;

	//printk(KERN_WARNING "%s: %p\n", __FUNCTION__, span);
	/* First make sure we're connected. */
	if (!span || span->magic != SPAN_AP_MAGIC || !netif_running(span->dev)) {
		return;
	}
	if (span->xleft <= 0)  {
		/* Now serial buffer is almost free & we can start
		 * transmission of another packet */
		span->tx_packets++;
		//		tty->flags &= ~(1 << TTY_DO_WRITE_WAKEUP);
		clear_bit(TTY_DO_WRITE_WAKEUP, &tty->flags);
		span_unlock(span);
		return;
	}

#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,25)
        actual = tty->driver->ops->write(tty, span->xhead, span->xleft);
#elif LINUX_VERSION_CODE > KERNEL_VERSION(2,6,8)
        actual = tty->driver->write(tty, span->xhead, span->xleft);
#else
        actual = tty->driver->write(tty, 0, span->xhead, span->xleft);
#endif
	span->xleft -= actual;
	span->xhead += actual;
}

/* Encapsulate an IP datagram and kick it into a TTY queue. */
/*
static void
span_printk(struct sk_buff *skb)
{
	int i;
	printk("Dumping...");
	for ( i = 0 ; i < skb->len ; i++ )
		printk("%02x:", skb->data[i]);
	printk("\n");
}
*/
static int
span_xmit(struct sk_buff *skb, struct net_device *dev)
{
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,28)		
	struct span_ap *span = (struct span_ap*)(netdev_priv(dev));
#else
	struct span_ap *span = (struct span_ap*)(dev->priv);
#endif
	// printk(KERN_WARNING "%s: %p\n", __FUNCTION__, span);

	spin_lock(&span->lock);
	if (!netif_running(dev))  {
		spin_unlock(&span->lock);
		printk(KERN_WARNING "%s: xmit call when iface is down\n", dev->name);
		dev_kfree_skb(skb);
		return 0;
	}
	if (span->tty == NULL) {
		spin_unlock(&span->lock);
		dev_kfree_skb(skb);
		return 0;
	}

	/* We need to prepend the information that this is a data packet */
	skb_push(skb,1)[0] = SPAN_DATA;
//	span_printk(skb);

	span_lock(span);
	span->tx_bytes += skb->len;
	span_encaps(span, skb->data, skb->len);
	spin_unlock(&span->lock);

	dev_kfree_skb(skb);
	return 0;
}

static int
span_send_reset(struct span_ap *span)
{
	unsigned char msg = 0;

//	printk(KERN_WARNING "%s: %p\n", __FUNCTION__, span);

	spin_lock(&span->lock);
	if (!netif_running(span->dev))  {
		spin_unlock(&span->lock);
		printk(KERN_WARNING "%s: xmit call when iface is down\n", span->dev->name);
		return 0;
	}
	if (span->tty == NULL) {
		spin_unlock(&span->lock);
		return 0;
	}

	/* The message is simply a single byte */
	span_lock(span);
	span->tx_bytes += 1;
	span_encaps(span, &msg, 1 );
	spin_unlock(&span->lock);
	return 0;
}


/******************************************
 *   Routines looking at netdevice side.
 ******************************************/

/* Netdevice UP -> DOWN routine */

static int
span_close(struct net_device *dev)
{
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,28)		
	struct span_ap *span = (struct span_ap*)(netdev_priv(dev));
#else
	struct span_ap *span = (struct span_ap*)(dev->priv);
#endif
	// printk(KERN_WARNING "%s: %p\n", __FUNCTION__, span);

	spin_lock_bh(&span->lock);
	if (span->tty) {
		/* TTY discipline is running. */
	  //		span->tty->flags &= ~(1 << TTY_DO_WRITE_WAKEUP);
	  clear_bit(TTY_DO_WRITE_WAKEUP, &span->tty->flags);
	}
	netif_stop_queue(dev);
	span->rcount   = 0;
	span->xleft    = 0;
	spin_unlock_bh(&span->lock);

	return 0;
}

/* Netdevice DOWN -> UP routine */

static int 
span_open(struct net_device *dev)
{
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,28)		
	struct span_ap *span = (struct span_ap*)(netdev_priv(dev));
#else
	struct span_ap *span = (struct span_ap*)(dev->priv);
#endif
//	printk(KERN_WARNING "%s: %p\n", __FUNCTION__, span);

	if (span->tty==NULL)
		return -ENODEV;
	
	span->flags &= (1 << SPANF_INUSE);
	netif_start_queue(dev);
	return 0;
}

/* Netdevice change MTU request */

static int 
span_change_mtu(struct net_device *dev, int new_mtu)
{
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,28)		
	struct span_ap *span = (struct span_ap*)(netdev_priv(dev));
#else
	struct span_ap *span = (struct span_ap*)(dev->priv);
#endif
	// printk(KERN_WARNING "%s: %p\n", __FUNCTION__, span);

	if (new_mtu < 68 || new_mtu > 65534)
		return -EINVAL;

	if (new_mtu != dev->mtu)
		return span_realloc_bufs(span, new_mtu);
	return 0;
}

/* Netdevice get statistics request */

static struct net_device_stats *
span_get_stats(struct net_device *dev)
{
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,28)		
	struct span_ap *span = (struct span_ap*)(netdev_priv(dev));
#else
	struct span_ap *span = (struct span_ap*)(dev->priv);
#endif
	static struct net_device_stats stats;
	// printk(KERN_WARNING "%s: %p\n", __FUNCTION__, span);

	memset(&stats, 0, sizeof(struct net_device_stats));

	stats.rx_packets     = span->rx_packets;
	stats.tx_packets     = span->tx_packets;
	stats.rx_bytes	     = span->rx_bytes;
	stats.tx_bytes	     = span->tx_bytes;
	stats.rx_dropped     = span->rx_dropped;
	stats.tx_dropped     = span->tx_dropped;
	stats.tx_errors      = span->tx_errors;
	stats.rx_errors      = span->rx_errors;
	stats.rx_over_errors = span->rx_over_errors;
	return (&stats);
}

/* Netdevice register callback */

static int 
span_init(struct net_device *dev)
{
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,28)		
	struct span_ap *span = (struct span_ap*)(netdev_priv(dev));
#else
	struct span_ap *span = (struct span_ap*)(dev->priv);
#endif
	// printk(KERN_WARNING "%s: %p\n", __FUNCTION__, span);

	dev->mtu	= span->mtu;
	dev->type	= ARPHRD_SPAN_AP;
	return 0;
}


static void 
span_uninit(struct net_device *dev)
{
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,28)		
	struct span_ap *span = (struct span_ap*)(netdev_priv(dev));
#else
	struct span_ap *span = (struct span_ap*)(dev->priv);
#endif
	// printk(KERN_WARNING "%s: %p\n", __FUNCTION__, span);

	span_free_bufs(span);
}

#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,29)
static const struct net_device_ops span_ops = {
	.ndo_init         = span_init,
	.ndo_uninit       = span_uninit,
	.ndo_open         = span_open,
	.ndo_stop         = span_close,
	.ndo_change_mtu   = span_change_mtu,
	.ndo_get_stats    = span_get_stats,
	.ndo_start_xmit   = span_xmit,
};
#endif

static void 
span_setup(struct net_device *dev)
{
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,29)

  dev->netdev_ops       = &span_ops;

#else

  dev->init		= span_init;
  dev->get_stats	= span_get_stats;
  dev->uninit	  	= span_uninit;
  dev->open		= span_open;
  dev->stop		= span_close;
  dev->change_mtu	= span_change_mtu;
  dev->hard_start_xmit	= span_xmit;

#endif

  dev->destructor		= free_netdev;
  dev->hard_header_len	= 0;
  dev->addr_len		= 0;
  dev->tx_queue_len	= 10;
  
  SET_MODULE_OWNER(dev);
  
  /* New-style flags. */
  //	dev->flags		= IFF_NOARP|IFF_POINTOPOINT|IFF_MULTICAST;
  dev->flags = IFF_NOARP;
}

/******************************************
  Routines looking at TTY side.
 ******************************************/

//#ifdef KERNEL_2_6_15_OR_LESS

#if LINUX_VERSION_CODE < KERNEL_VERSION(2,6,16)


static int 
span_ap_receive_room(struct tty_struct *tty)
{
	return 65536;  /* We can handle an infinite amount of data. :-) */
}

#endif

/*
 * Handle the 'receiver data ready' interrupt.
 * This function is called by the 'tty_io' module in the kernel when
 * a block of SPAN_AP data has been received, which can now be decapsulated
 * and sent on to some IP layer for further processing.
 */
 
static void 
span_ap_receive_buf(struct tty_struct *tty, const unsigned char *cp, char *fp, int count)
{
	struct span_ap *span = (struct span_ap *) tty->disc_data;
	// printk(KERN_WARNING "%s: %p\n", __FUNCTION__, span);

	if (!span || span->magic != SPAN_AP_MAGIC ||
	    !netif_running(span->dev))
		return;

	/* Read the characters out of the buffer */
	while (count--) {
		if (fp && *fp++) {
			if (!test_and_set_bit(SPANF_ERROR, &span->flags))  {
				span->rx_errors++;
			}
			cp++;
			continue;
		}
		span_ap_unesc(span, *cp++);
	}
}

/************************************
 *  span_ap_open helper routines.
 ************************************/

/* Collect hanged up channels */

static void 
span_sync(void)
{
	int i;
	struct net_device *dev;
	struct span_ap	  *span;
	// printk(KERN_WARNING "%s\n", __FUNCTION__);

	for (i = 0; i < span_ap_maxdev; i++) {
		if ((dev = span_ap_devs[i]) == NULL)
			break;

#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,28)		
		span = (netdev_priv(dev));
#else
		span = dev->priv;
#endif
		if (span->tty)
			continue;
		if (dev->flags&IFF_UP)
			dev_close(dev);
	}
}


/* Find a free SPAN_AP channel, and link in this `tty' line. */
static struct span_ap *
span_alloc(dev_t line)
{
	int i;
	int sel = -1;
	int score = -1;
	struct net_device *dev = NULL;
	struct span_ap       *span;

	// printk(KERN_WARNING "%s\n", __FUNCTION__);

	if (span_ap_devs == NULL) 
		return NULL;	/* Master array missing ! */

	for (i = 0; i < span_ap_maxdev; i++) {
		dev = span_ap_devs[i];
		if (dev == NULL)
			break;

#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,28)		
		span = (netdev_priv(dev));
#else
		span = dev->priv;
#endif
		if (span->tty)
			continue;

		if (current->pid == span->pid) {
			if (span->line == line && score < 3) {
				sel = i;
				score = 3;
				continue;
			}
			if (score < 2) {
				sel = i;
				score = 2;
			}
			continue;
		}
		if (span->line == line && score < 1) {
			sel = i;
			score = 1;
			continue;
		}
		if (score < 0) {
			sel = i;
			score = 0;
		}
	}

	if (sel >= 0) {
		i = sel;
		dev = span_ap_devs[i];
		if (score > 1) {
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,28)		
		  span = (netdev_priv(dev));
#else
		  span = dev->priv;
#endif
		  span->flags &= (1 << SPANF_INUSE);
		  return span;
		}
	}

	/* Sorry, too many, all slots in use */
	if (i >= span_ap_maxdev)
		return NULL;

	if (dev) {
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,28)		
	  span = (netdev_priv(dev));
#else
	  span = dev->priv;
#endif
	  if (test_bit(SPANF_INUSE, &span->flags)) {
	    unregister_netdevice(dev);
	    dev = NULL;
	    span_ap_devs[i] = NULL;
	  }
	}
	
	if (!dev) {
		char name[IFNAMSIZ];
		sprintf(name, "span%d", i);

		dev = alloc_netdev(sizeof(*span), name, span_setup);
		if (!dev)
			return NULL;
		dev->base_addr  = i;
	}

#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,28)		
	span = (netdev_priv(dev));
#else
	span = dev->priv;
#endif

	/* Initialize channel control data */
	span->magic       = SPAN_AP_MAGIC;
	span->dev	      	= dev;
	spin_lock_init(&span->lock);
	span_ap_devs[i] = dev;
				   
	return span;
}

/*
 * Open the high-level part of the SPAN_AP channel.
 * This function is called by the TTY module when the
 * SPAN_AP line discipline is called for.  Because we are
 * sure the tty line exists, we only have to link it to
 * a free SPAN_AP channel...
 */
static int
span_ap_open(struct tty_struct *tty)
{
	struct span_ap *span;
	int err;

	// printk(KERN_WARNING "%s\n", __FUNCTION__);

	if(!capable(CAP_NET_ADMIN))
		return -EPERM;

#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,30)
	if(tty->ops->write == NULL)
	  return -EOPNOTSUPP;
#endif
	/* RTnetlink lock is misused here to serialize concurrent
	   opens of span_ap channels. There are better ways, but it is
	   the simplest one.
	 */
	rtnl_lock();

	/* Collect hanged up channels. */
	span_sync();

	span = (struct span_ap *) tty->disc_data;

	err = -EEXIST;
	/* First make sure we're not already connected. */
	if (span && span->magic == SPAN_AP_MAGIC)
		goto err_exit;

	/* OK.  Find a free SPAN_AP channel to use. */
	err = -ENFILE;
	if ((span = span_alloc(tty_devnum(tty))) == NULL)
		goto err_exit;

	span->tty      = tty;
	tty->disc_data = span;
	span->line    = tty_devnum(tty);
	span->pid     = current->pid;


#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,25)
	if (tty->driver->ops->flush_buffer)
		tty->driver->ops->flush_buffer(tty);
#else
	if (tty->driver->flush_buffer)
		tty->driver->flush_buffer(tty);
#endif

#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,30)
	if (tty->ldisc->ops->flush_buffer)
		tty->ldisc->ops->flush_buffer(tty);
#elif LINUX_VERSION_CODE > KERNEL_VERSION(2,6,26)
	if (tty->ldisc.ops->flush_buffer)
		tty->ldisc.ops->flush_buffer(tty);
#else
	if (tty->ldisc.flush_buffer)
		tty->ldisc.flush_buffer(tty);
#endif

	if (!test_bit(SPANF_INUSE, &span->flags)) {
		/* Perform the low-level SPAN_AP initialization. */
		if ((err = span_alloc_bufs(span, SPAN_MTU)) != 0)
			goto err_free_chan;

		set_bit(SPANF_INUSE, &span->flags);

		if ((err = register_netdevice(span->dev)))
			goto err_free_bufs;
	}

	/* Done.  We have linked the TTY line to a channel. */
	rtnl_unlock();
	tty->receive_room = 65536;         /* We don't flow control */
	return span->dev->base_addr;

err_free_bufs:
	span_free_bufs(span);

err_free_chan:
	span->tty = NULL;
	tty->disc_data = NULL;
	clear_bit(SPANF_INUSE, &span->flags);

err_exit:
	rtnl_unlock();

	/* Count references from TTY module */
	return err;
}

/*
   Let me to blame a bit.
   1. TTY module calls this funstion on soft interrupt.
   2. TTY module calls this function WITH MASKED INTERRUPTS!
   3. TTY module does not notify us about line discipline
      shutdown,

   Seems, now it is clean. The solution is to consider netdevice and
   line discipline sides as two independent threads.

   By-product (not desired): span? does not feel hangups and remains open.
   It is supposed, that user level program (dip, diald, slattach...)
   will catch SIGHUP and make the rest of work. 

   I see no way to make more with current tty code. --ANK
 */

/*
 * Close down a SPAN_AP channel.
 * This means flushing out any pending queues, and then restoring the
 * TTY line discipline to what it was before it got hooked to SPAN_AP
 * (which usually is TTY again).
 */
static void
span_ap_close(struct tty_struct *tty)
{
	struct span_ap *span = (struct span_ap *) tty->disc_data;

	// printk(KERN_WARNING "%s: %p\n", __FUNCTION__, span);

	/* First make sure we're connected. */
	if (!span || span->magic != SPAN_AP_MAGIC || span->tty != tty)
		return;

	tty->disc_data = NULL;
	span->tty = NULL;
	span->line = 0;

	/* Count references from TTY module */
}

static void
span_ap_flush_buffer(struct tty_struct *tty)
{
	unsigned long flags;
	struct span_ap *span = (struct span_ap *) tty->disc_data;
	
	spin_lock_irqsave(&tty->read_lock, flags);
	span->read_queue_tail = span->read_queue_head = 0;
	spin_unlock_irqrestore(&tty->read_lock, flags);
}

static ssize_t
span_ap_chars_in_buffer(struct tty_struct *tty)
{
	unsigned long flags;
	struct span_ap *span = (struct span_ap *) tty->disc_data;
	ssize_t n;

	spin_lock_irqsave(&tty->read_lock, flags);
	n = (SPAN_READ_QUEUE_DEPTH + span->read_queue_head - span->read_queue_tail) % SPAN_READ_QUEUE_DEPTH;
	n *= sizeof(span->read_queue[0]);
	spin_unlock_irqrestore(&tty->read_lock, flags);
	
	return n;
}

static struct SpanInform *
span_ap_pop_message( struct tty_struct *tty )
{
	struct span_ap *span = (struct span_ap *) tty->disc_data;
	unsigned long flags;
	struct SpanInform *info = NULL;

	spin_lock_irqsave(&tty->read_lock, flags);
	if (span->read_queue_head != span->read_queue_tail) {
		info = span->read_queue + span->read_queue_tail;
		span->read_queue_tail++;
		if ( span->read_queue_tail >= SPAN_READ_QUEUE_DEPTH )
			span->read_queue_tail = 0;
	}
	spin_unlock_irqrestore(&tty->read_lock, flags);
	return info;
}

static ssize_t
span_ap_read(struct tty_struct *tty, struct file *file, unsigned char *buf, size_t nr)
{
	struct SpanInform *info;
	DECLARE_WAITQUEUE(wait, current);

	/* You must specify at least enough room for one buffer */
	if (nr < sizeof(*info))
		return -EIO;

	info = span_ap_pop_message(tty);
	if ( !info ) {
		if (file->f_flags & O_NONBLOCK) 
			return -EAGAIN;

		add_wait_queue(&tty->read_wait, &wait);
	repeat:
		current->state = TASK_INTERRUPTIBLE;
		info = span_ap_pop_message(tty);
		if ( !info && !signal_pending(current)) {
			schedule();
			goto repeat;
		}
		current->state = TASK_RUNNING;
		remove_wait_queue(&tty->read_wait, &wait);
	}

	if (!info)  /* Must have gotten a signal */
		return -EINTR;

	if (copy_to_user(buf,info,sizeof(*info)))
		return -EFAULT;

	return sizeof(*info);
}

static unsigned int
span_ap_poll(struct tty_struct *tty, struct file *file, struct poll_table_struct *wait)
{
	struct span_ap *span = (struct span_ap *) tty->disc_data;

	poll_wait(file, &tty->read_wait, wait );
	if ( span->read_queue_head != span->read_queue_tail )
		return POLLIN | POLLRDNORM;

	return 0;
}

 /************************************************************************
  *			STANDARD SPAN_AP ENCAPSULATION		  	 *
  ************************************************************************/

int
span_ap_esc(unsigned char *s, unsigned char *d, int len)
{
	unsigned char *ptr = d;
	unsigned char c;

	// printk(KERN_WARNING "%s\n", __FUNCTION__);
	/*
	 * Send an initial FRAME character to flush out any
	 * data that may have accumulated in the receiver
	 * due to line noise.
	 */

	*ptr++ = FRAME;

	/*
	 * For each byte in the packet, send the appropriate
	 * character sequence, according to the SPAN_AP protocol.
	 */

	while (len-- > 0) {
		switch(c = *s++) {
		case FRAME:
		case ESCAPE_BYTE:
			*ptr++ = ESCAPE_BYTE;
			*ptr++ = c ^ 0x20;
			break;
		default:
			*ptr++ = c;
			break;
		}
	}
	*ptr++ = FRAME;
	return (ptr - d);
}

static void span_ap_unesc(struct span_ap *span, unsigned char s)
{
	// printk(KERN_WARNING "%s: %p\n", __FUNCTION__, span);

	switch(s) {
	 case FRAME:
		if (!test_and_clear_bit(SPANF_ERROR, &span->flags) && (span->rcount > 2))  {
			span_bump(span);
		}
		clear_bit(SPANF_ESCAPE, &span->flags);
		span->rcount = 0;
		return;

	 case ESCAPE_BYTE:
		set_bit(SPANF_ESCAPE, &span->flags);
		return;
	}
	if (!test_bit(SPANF_ERROR, &span->flags))  {
		if (span->rcount < span->buffsize)  {
			if (test_and_clear_bit(SPANF_ESCAPE, &span->flags))
				span->rbuff[span->rcount++] = s ^ 0x20;
			else
				span->rbuff[span->rcount++] = s;
			return;
		}
		span->rx_over_errors++;
		set_bit(SPANF_ERROR, &span->flags);
	}
}


/* Perform I/O control on an active SPAN_AP channel. */
static int span_ap_ioctl(struct tty_struct *tty, struct file *file, unsigned int cmd, unsigned long arg)
{
	struct span_ap *span = (struct span_ap *) tty->disc_data;

	/* First make sure we're connected. */
	if (!span || span->magic != SPAN_AP_MAGIC) {
		return -EINVAL;
	}

	switch(cmd) {
	case SIOCGDEVNAME:   // Assume buffer of size IFNAMSIZ
		if (copy_to_user((void *)arg, &span->dev->name, IFNAMSIZ))
			return -EFAULT;
		return 0;
		
	case SIOCGRESET:
		return span_send_reset(span);
		/* Allow stty to read, but not set, the serial port */
	case TCGETS:
	case TCGETA:
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,27)
		return n_tty_ioctl_helper(tty, file, cmd, arg);
#else
		return n_tty_ioctl(tty, file, cmd, arg);
#endif
	default:
		return -ENOIOCTLCMD;
	}
}

#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,26)
static struct tty_ldisc_ops span_ldisc = {
	.owner 		 = THIS_MODULE,
	.magic 		 = TTY_LDISC_MAGIC,
	.name 		 = "span_ap",
	.open 		 = span_ap_open,
	.close	 	 = span_ap_close,
	.flush_buffer    = span_ap_flush_buffer,
	.chars_in_buffer = span_ap_chars_in_buffer,
	.read            = span_ap_read,
	.ioctl		 = span_ap_ioctl,
	.poll            = span_ap_poll,
	.receive_buf	 = span_ap_receive_buf,
	.write_wakeup	 = span_ap_write_wakeup,
};
#else
static struct tty_ldisc span_ldisc = {
	.owner 		 = THIS_MODULE,
	.magic 		 = TTY_LDISC_MAGIC,
	.name 		 = "span_ap",
	.open 		 = span_ap_open,
	.close	 	 = span_ap_close,
	.flush_buffer    = span_ap_flush_buffer,
	.chars_in_buffer = span_ap_chars_in_buffer,
	.read            = span_ap_read,
	.ioctl		 = span_ap_ioctl,
	.poll            = span_ap_poll,
	.receive_buf	 = span_ap_receive_buf,

//#ifdef KERNEL_2_6_15_OR_LESS
#if LINUX_VERSION_CODE < KERNEL_VERSION(2,6,16)
	.receive_room	 = span_ap_receive_room,
#endif
	.write_wakeup	 = span_ap_write_wakeup,
};
#endif

static int __init span_ap_init(void)
{
	int status;

	// printk(KERN_WARNING "%s\n", __FUNCTION__);

	if (span_ap_maxdev < 4)
		span_ap_maxdev = 4; /* Sanity */

	printk(KERN_INFO "SPAN_AP: version %s (dynamic channels, max=%d).\n",
	       SPAN_AP_VERSION, span_ap_maxdev );
	//	span_ap_devs = kmalloc(sizeof(struct net_device *)*span_ap_maxdev, GFP_KERNEL);
	span_ap_devs = kzalloc(sizeof(struct net_device *)*span_ap_maxdev, GFP_KERNEL);
	if (!span_ap_devs) {
		printk(KERN_ERR "SPAN_AP: Can't allocate span_ap devices array!  Uaargh! (-> No SPAN_AP available)\n");
		return -ENOMEM;
	}

	/* Clear the pointer array, we allocate devices when we need them */
	// changed to kzalloc, don't need this
	//	memset(span_ap_devs, 0, sizeof(struct net_device *)*span_ap_maxdev); 

	/* Fill in our line protocol discipline, and register it */
	//if ((status = tty_register_ldisc(N_SPAN_AP, &span_ldisc)) != 0)  {
	if ((status = tty_register_ldisc(1, &span_ldisc)) != 0)  {
		printk(KERN_ERR "SPAN_AP: can't register line discipline (err = %d)\n", status);
		kfree(span_ap_devs);
	}
	return status;
}

static void __exit span_ap_exit(void)
{
	int i;
	struct net_device *dev;
	struct span_ap *span;
	unsigned long timeout = jiffies + HZ;
	int busy = 0;

	// printk(KERN_WARNING "%s\n", __FUNCTION__);

	if (span_ap_devs == NULL) 
		return;

	/* First of all: check for active disciplines and hangup them.
	 */
	do {
		if (busy) {
		  /*
			set_current_state(TASK_INTERRUPTIBLE);
			schedule_timeout(HZ / 10);
		  */
		  msleep_interruptible(100);
		}

		busy = 0;
		for (i = 0; i < span_ap_maxdev; i++) {
			dev = span_ap_devs[i];
			if (!dev)
				continue;
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,28)		
			span = (netdev_priv(dev));
#else
			span = dev->priv;
#endif
			spin_lock_bh(&span->lock);
			if (span->tty) {
				busy++;
				tty_hangup(span->tty);
			}
			spin_unlock_bh(&span->lock);
		}
	} while (busy && time_before(jiffies, timeout));


	for (i = 0; i < span_ap_maxdev; i++) {
		dev = span_ap_devs[i];
		if (!dev)
			continue;
		span_ap_devs[i] = NULL;

#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,28)		
		span = (netdev_priv(dev));
#else
		span = dev->priv;
#endif
		if (span->tty) {
			printk(KERN_ERR "%s: tty discipline still running\n",
			       dev->name);
			/* Intentionally leak the control block. */
			dev->destructor = NULL;
		} 

		unregister_netdev(dev);
	}

	kfree(span_ap_devs);
	span_ap_devs = NULL;

	// We steal SLIP
//	if ((i = tty_register_ldisc(N_SPAN_AP, NULL)))
//	if ((i = tty_register_ldisc(1, NULL)))
	if ((i = tty_unregister_ldisc(1)))
	{
		printk(KERN_ERR "SPAN_AP: can't unregister line discipline (err = %d)\n", i);
	}
}

module_init(span_ap_init);
module_exit(span_ap_exit);

MODULE_LICENSE("GPL");
MODULE_ALIAS_LDISC(N_SPAN_AP);
