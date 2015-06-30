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
#include <linux/config.h>
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
#include "if_telos_ap.h"
#include <linux/init.h>
#include "telos_ap.h"
#ifdef CONFIG_INET
#include <linux/ip.h>
#include <linux/tcp.h>
#include <linux/version.h>
#include <net/slhc_vj.h>
#endif
#include <asm/unaligned.h>

#define TELOS_AP_VERSION	"0.8"

static struct net_device **telos_ap_devs;

int telos_ap_maxdev = TELOS_NRUNIT;		/* Can be overridden with insmod! */
MODULE_PARM(telos_ap_maxdev, "i");
MODULE_PARM_DESC(telos_ap_maxdev, "Maximum number of telos_ap devices");

static int telos_ap_esc(unsigned char *p, unsigned char *d, int len);
static void telos_ap_unesc(struct telos_ap *sl, unsigned char c);

/********************************
*  Buffer administration routines:
*	telos_alloc_bufs()
*	telos_free_bufs()
*	telos_realloc_bufs()
*
* NOTE: telos_realloc_bufs != telos_free_bufs + telos_alloc_bufs, because
*	telos_realloc_bufs provides strong atomicity and reallocation
*	on actively running device.
*********************************/

/* 
   Allocate channel buffers.
 */

static int
telos_alloc_bufs(struct telos_ap *telos, int mtu)
{
	int err = -ENOBUFS;
	unsigned long len;
	char * rbuff = NULL;
	char * xbuff = NULL;

	// printk(KERN_WARNING "%s: %p\n", __FUNCTION__, telos);

	/*
	 * Allocate the TELOS_AP frame buffers:
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
	spin_lock_bh(&telos->lock);
	if (telos->tty == NULL) {
		spin_unlock_bh(&telos->lock);
		err = -ENODEV;
		goto err_exit;
	}
	telos->mtu	     = mtu;
	telos->buffsize = len;
	telos->rcount   = 0;
	telos->xleft    = 0;
	rbuff = xchg(&telos->rbuff, rbuff);
	xbuff = xchg(&telos->xbuff, xbuff);
	spin_unlock_bh(&telos->lock);
	err = 0;

	/* Cleanup */
err_exit:
	if (xbuff)
		kfree(xbuff);
	if (rbuff)
		kfree(rbuff);
	return err;
}

/* Free a TELOS_AP channel buffers. */
static void
telos_free_bufs(struct telos_ap *telos)
{
	void * tmp;

	// printk(KERN_WARNING "%s: %p\n", __FUNCTION__, telos);

	/* Free all TELOS_AP frame buffers. */
	if ((tmp = xchg(&telos->rbuff, NULL)) != NULL)
		kfree(tmp);
	if ((tmp = xchg(&telos->xbuff, NULL)) != NULL)
		kfree(tmp);
}

/* 
   Reallocate telos_ap channel buffers.
 */

static int telos_realloc_bufs(struct telos_ap *telos, int mtu)
{
	int err = 0;
	struct net_device *dev = telos->dev;
	unsigned char *xbuff, *rbuff;
	int len = mtu * 2;

	// printk(KERN_WARNING "%s: %p\n", __FUNCTION__, telos);
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
		if (mtu >= telos->mtu) {
			printk(KERN_WARNING "%s: unable to grow telos_ap buffers, MTU change cancelled.\n",
			       dev->name);
			err = -ENOBUFS;
		}
		goto done;
	}

	spin_lock_bh(&telos->lock);

	err = -ENODEV;
	if (telos->tty == NULL)
		goto done_on_bh;

	xbuff    = xchg(&telos->xbuff, xbuff);
	rbuff    = xchg(&telos->rbuff, rbuff);
	if (telos->xleft)  {
		if (telos->xleft <= len)  {
			memcpy(telos->xbuff, telos->xhead, telos->xleft);
		} else  {
			telos->xleft = 0;
			telos->tx_dropped++;
		}
	}
	telos->xhead = telos->xbuff;

	if (telos->rcount)  {
		if (telos->rcount <= len) {
			memcpy(telos->rbuff, rbuff, telos->rcount);
		} else  {
			telos->rcount = 0;
			telos->rx_over_errors++;
			set_bit(TELOSF_ERROR, &telos->flags);
		}
	}
	telos->mtu      = mtu;
	dev->mtu      = mtu;
	telos->buffsize = len;
	err = 0;

done_on_bh:
	spin_unlock_bh(&telos->lock);

done:
	if (xbuff)
		kfree(xbuff);
	if (rbuff)
		kfree(rbuff);
	return err;
}


/* Set the "sending" flag.  This must be atomic hence the set_bit. */
static inline void
telos_lock(struct telos_ap *telos)
{
	// printk(KERN_WARNING "%s: %p\n", __FUNCTION__, telos);
	netif_stop_queue(telos->dev);
}


/* Clear the "sending" flag.  This must be atomic, hence the ASM. */
static inline void
telos_unlock(struct telos_ap *telos)
{
	// printk(KERN_WARNING "%s: %p\n", __FUNCTION__, telos);
	netif_wake_queue(telos->dev);
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
telos_ap_add_message(struct telos_ap *telos)
{
	struct TelosInform *ti;
	int n = (telos->read_queue_head + 1) % TELOS_READ_QUEUE_DEPTH;

	if ( n == telos->read_queue_tail ) {
		printk("Telos dropped message from client\n");
		return;
	}

	ti = telos->read_queue + telos->read_queue_head;
	memset( ti, 0, sizeof(*ti));

	memcpy( &ti->ip, telos->rbuff+1, 4 );
	memcpy( &ti->l_addr, telos->rbuff+5, 8 );
	memcpy( &ti->s_addr, telos->rbuff+13, 2 );
	if ( telos->rbuff[0] == 0 ) {
		memcpy( &ti->frequency, telos->rbuff+15, 2 );
		strncpy( ti->ssid, telos->rbuff+17, 32 );
	}
	else {
		ti->event = telos->rbuff[15];
		ti->flags = telos->rbuff[16];
	}
		
	telos->read_queue_head = n;
	wake_up_interruptible(&telos->tty->read_wait);
}

static void
telos_bump(struct telos_ap *telos)
{
	struct sk_buff *skb;
	int count;

//	printk(KERN_WARNING "%s: %p\n", __FUNCTION__, telos);
	count = telos->rcount;
	telos->rx_bytes+=count;
	
	switch (telos->rbuff[0]) {
	case TELOS_RESET:
//		printk("Telos received reset message length %d\n", count );
		telos_ap_add_message( telos );
		break;

	case TELOS_MESSAGE:
//		printk("Telos adding message length %d type %d\n", count, telos->rbuff[15]);
		telos_ap_add_message( telos );
		break;
		
	case TELOS_DATA:
		// Encapsulated IP data packet
//		printk("Telos DATA packet\n");
		skb = dev_alloc_skb(count);
		if (skb == NULL)  {
			printk(KERN_WARNING "%s: memory squeeze, dropping packet.\n", telos->dev->name);
			telos->rx_dropped++;
			return;
		}
		skb->dev = telos->dev;
		memcpy(skb_put(skb,count - 1), telos->rbuff + 1, count - 1);
		skb->mac.raw=skb->data;
		skb->protocol=htons(ETH_P_IP);
		netif_rx(skb);
		break;

	case TELOS_RESPONSE:
		// Response to a request
		break;
	}

	telos->dev->last_rx = jiffies;
	telos->rx_packets++;
}

/* Encapsulate one IP datagram and stuff into a TTY queue. */
static void
telos_encaps(struct telos_ap *telos, unsigned char *icp, int len)
{
	unsigned char *p;
	int actual, count;

	// printk(KERN_WARNING "%s: %p\n", __FUNCTION__, telos);
	if (len > telos->mtu) {		/* Sigh, shouldn't occur BUT ... */
		printk(KERN_WARNING "%s: truncating oversized transmit packet!\n", telos->dev->name);
		telos->tx_dropped++;
		telos_unlock(telos);
		return;
	}

	p = icp;
	count = telos_ap_esc(p, (unsigned char *) telos->xbuff, len);

	/* Order of next two lines is *very* important.
	 * When we are sending a little amount of data,
	 * the transfer may be completed inside driver.write()
	 * routine, because it's running with interrupts enabled.
	 * In this case we *never* got WRITE_WAKEUP event,
	 * if we did not request it before write operation.
	 *       14 Oct 1994  Dmitry Gorodchanin.
	 */
	telos->tty->flags |= (1 << TTY_DO_WRITE_WAKEUP);
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,8)
        actual = telos->tty->driver->write(telos->tty, telos->xbuff, count);
#else
	actual = telos->tty->driver->write(telos->tty, 0, telos->xbuff, count);
#endif
	telos->xleft = count - actual;
	telos->xhead = telos->xbuff + actual;
}

/*
 * Called by the driver when there's room for more data.  If we have
 * more packets to send, we send them here.
 */
static void 
telos_ap_write_wakeup(struct tty_struct *tty)
{
	int actual;
	struct telos_ap *telos = (struct telos_ap *) tty->disc_data;

	// printk(KERN_WARNING "%s: %p\n", __FUNCTION__, telos);
	/* First make sure we're connected. */
	if (!telos || telos->magic != TELOS_AP_MAGIC || !netif_running(telos->dev)) {
		return;
	}
	if (telos->xleft <= 0)  {
		/* Now serial buffer is almost free & we can start
		 * transmission of another packet */
		telos->tx_packets++;
		tty->flags &= ~(1 << TTY_DO_WRITE_WAKEUP);
		telos_unlock(telos);
		return;
	}

#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,8)
        actual = tty->driver->write(tty, telos->xhead, telos->xleft);
#else
        actual = tty->driver->write(tty, 0, telos->xhead, telos->xleft);
#endif
	telos->xleft -= actual;
	telos->xhead += actual;
}

/* Encapsulate an IP datagram and kick it into a TTY queue. */
/*
static void
telos_printk(struct sk_buff *skb)
{
	int i;
	printk("Dumping...");
	for ( i = 0 ; i < skb->len ; i++ )
		printk("%02x:", skb->data[i]);
	printk("\n");
}
*/
static int
telos_xmit(struct sk_buff *skb, struct net_device *dev)
{
	struct telos_ap *telos = (struct telos_ap*)(dev->priv);
	// printk(KERN_WARNING "%s: %p\n", __FUNCTION__, telos);

	spin_lock(&telos->lock);
	if (!netif_running(dev))  {
		spin_unlock(&telos->lock);
		printk(KERN_WARNING "%s: xmit call when iface is down\n", dev->name);
		dev_kfree_skb(skb);
		return 0;
	}
	if (telos->tty == NULL) {
		spin_unlock(&telos->lock);
		dev_kfree_skb(skb);
		return 0;
	}

	/* We need to prepend the information that this is a data packet */
	skb_push(skb,1)[0] = TELOS_DATA;
//	telos_printk(skb);

	telos_lock(telos);
	telos->tx_bytes += skb->len;
	telos_encaps(telos, skb->data, skb->len);
	spin_unlock(&telos->lock);

	dev_kfree_skb(skb);
	return 0;
}

static int
telos_send_reset(struct telos_ap *telos)
{
	unsigned char msg = 0;

//	printk(KERN_WARNING "%s: %p\n", __FUNCTION__, telos);

	spin_lock(&telos->lock);
	if (!netif_running(telos->dev))  {
		spin_unlock(&telos->lock);
		printk(KERN_WARNING "%s: xmit call when iface is down\n", telos->dev->name);
		return 0;
	}
	if (telos->tty == NULL) {
		spin_unlock(&telos->lock);
		return 0;
	}

	/* The message is simply a single byte */
	telos_lock(telos);
	telos->tx_bytes += 1;
	telos_encaps(telos, &msg, 1 );
	spin_unlock(&telos->lock);
	return 0;
}


/******************************************
 *   Routines looking at netdevice side.
 ******************************************/

/* Netdevice UP -> DOWN routine */

static int
telos_close(struct net_device *dev)
{
	struct telos_ap *telos = (struct telos_ap*)(dev->priv);
	// printk(KERN_WARNING "%s: %p\n", __FUNCTION__, telos);

	spin_lock_bh(&telos->lock);
	if (telos->tty) {
		/* TTY discipline is running. */
		telos->tty->flags &= ~(1 << TTY_DO_WRITE_WAKEUP);
	}
	netif_stop_queue(dev);
	telos->rcount   = 0;
	telos->xleft    = 0;
	spin_unlock_bh(&telos->lock);

	return 0;
}

/* Netdevice DOWN -> UP routine */

static int 
telos_open(struct net_device *dev)
{
	struct telos_ap *telos = (struct telos_ap*)(dev->priv);
//	printk(KERN_WARNING "%s: %p\n", __FUNCTION__, telos);

	if (telos->tty==NULL)
		return -ENODEV;
	
	telos->flags &= (1 << TELOSF_INUSE);
	netif_start_queue(dev);
	return 0;
}

/* Netdevice change MTU request */

static int 
telos_change_mtu(struct net_device *dev, int new_mtu)
{
	struct telos_ap *telos = (struct telos_ap*)(dev->priv);
	// printk(KERN_WARNING "%s: %p\n", __FUNCTION__, telos);

	if (new_mtu < 68 || new_mtu > 65534)
		return -EINVAL;

	if (new_mtu != dev->mtu)
		return telos_realloc_bufs(telos, new_mtu);
	return 0;
}

/* Netdevice get statistics request */

static struct net_device_stats *
telos_get_stats(struct net_device *dev)
{
	static struct net_device_stats stats;
	struct telos_ap *telos = (struct telos_ap*)(dev->priv);
	// printk(KERN_WARNING "%s: %p\n", __FUNCTION__, telos);

	memset(&stats, 0, sizeof(struct net_device_stats));

	stats.rx_packets     = telos->rx_packets;
	stats.tx_packets     = telos->tx_packets;
	stats.rx_bytes	     = telos->rx_bytes;
	stats.tx_bytes	     = telos->tx_bytes;
	stats.rx_dropped     = telos->rx_dropped;
	stats.tx_dropped     = telos->tx_dropped;
	stats.tx_errors      = telos->tx_errors;
	stats.rx_errors      = telos->rx_errors;
	stats.rx_over_errors = telos->rx_over_errors;
	return (&stats);
}

/* Netdevice register callback */

static int 
telos_init(struct net_device *dev)
{
	struct telos_ap *telos = (struct telos_ap*)(dev->priv);
	// printk(KERN_WARNING "%s: %p\n", __FUNCTION__, telos);

	dev->mtu	= telos->mtu;
	dev->type	= ARPHRD_TELOS_AP;
	return 0;
}


static void 
telos_uninit(struct net_device *dev)
{
	struct telos_ap *telos = (struct telos_ap*)(dev->priv);
	// printk(KERN_WARNING "%s: %p\n", __FUNCTION__, telos);

	telos_free_bufs(telos);
}

static void 
telos_setup(struct net_device *dev)
{
	dev->init		= telos_init;
	dev->uninit	  	= telos_uninit;
	dev->open		= telos_open;
	dev->destructor		= free_netdev;
	dev->stop		= telos_close;
	dev->get_stats	        = telos_get_stats;
	dev->change_mtu		= telos_change_mtu;
	dev->hard_start_xmit	= telos_xmit;
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


static int 
telos_ap_receive_room(struct tty_struct *tty)
{
	return 65536;  /* We can handle an infinite amount of data. :-) */
}

/*
 * Handle the 'receiver data ready' interrupt.
 * This function is called by the 'tty_io' module in the kernel when
 * a block of TELOS_AP data has been received, which can now be decapsulated
 * and sent on to some IP layer for further processing.
 */
 
static void 
telos_ap_receive_buf(struct tty_struct *tty, const unsigned char *cp, char *fp, int count)
{
	struct telos_ap *telos = (struct telos_ap *) tty->disc_data;
	// printk(KERN_WARNING "%s: %p\n", __FUNCTION__, telos);

	if (!telos || telos->magic != TELOS_AP_MAGIC ||
	    !netif_running(telos->dev))
		return;

	/* Read the characters out of the buffer */
	while (count--) {
		if (fp && *fp++) {
			if (!test_and_set_bit(TELOSF_ERROR, &telos->flags))  {
				telos->rx_errors++;
			}
			cp++;
			continue;
		}
		telos_ap_unesc(telos, *cp++);
	}
}

/************************************
 *  telos_ap_open helper routines.
 ************************************/

/* Collect hanged up channels */

static void 
telos_sync(void)
{
	int i;
	struct net_device *dev;
	struct telos_ap	  *telos;
	// printk(KERN_WARNING "%s\n", __FUNCTION__);

	for (i = 0; i < telos_ap_maxdev; i++) {
		if ((dev = telos_ap_devs[i]) == NULL)
			break;

		telos = dev->priv;
		if (telos->tty)
			continue;
		if (dev->flags&IFF_UP)
			dev_close(dev);
	}
}


/* Find a free TELOS_AP channel, and link in this `tty' line. */
static struct telos_ap *
telos_alloc(dev_t line)
{
	int i;
	int sel = -1;
	int score = -1;
	struct net_device *dev = NULL;
	struct telos_ap       *telos;

	// printk(KERN_WARNING "%s\n", __FUNCTION__);

	if (telos_ap_devs == NULL) 
		return NULL;	/* Master array missing ! */

	for (i = 0; i < telos_ap_maxdev; i++) {
		dev = telos_ap_devs[i];
		if (dev == NULL)
			break;

		telos = dev->priv;

		if (telos->tty)
			continue;

		if (current->pid == telos->pid) {
			if (telos->line == line && score < 3) {
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
		if (telos->line == line && score < 1) {
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
		dev = telos_ap_devs[i];
		if (score > 1) {
			telos = dev->priv;
			telos->flags &= (1 << TELOSF_INUSE);
			return telos;
		}
	}

	/* Sorry, too many, all slots in use */
	if (i >= telos_ap_maxdev)
		return NULL;

	if (dev) {
		telos = dev->priv;
		if (test_bit(TELOSF_INUSE, &telos->flags)) {
			unregister_netdevice(dev);
			dev = NULL;
			telos_ap_devs[i] = NULL;
		}
	}
	
	if (!dev) {
		char name[IFNAMSIZ];
		sprintf(name, "telos%d", i);

		dev = alloc_netdev(sizeof(*telos), name, telos_setup);
		if (!dev)
			return NULL;
		dev->base_addr  = i;
	}

	telos = dev->priv;

	/* Initialize channel control data */
	telos->magic       = TELOS_AP_MAGIC;
	telos->dev	      	= dev;
	spin_lock_init(&telos->lock);
	telos_ap_devs[i] = dev;
				   
	return telos;
}

/*
 * Open the high-level part of the TELOS_AP channel.
 * This function is called by the TTY module when the
 * TELOS_AP line discipline is called for.  Because we are
 * sure the tty line exists, we only have to link it to
 * a free TELOS_AP channel...
 */
static int
telos_ap_open(struct tty_struct *tty)
{
	struct telos_ap *telos;
	int err;

	// printk(KERN_WARNING "%s\n", __FUNCTION__);

	if(!capable(CAP_NET_ADMIN))
		return -EPERM;
		
	/* RTnetlink lock is misused here to serialize concurrent
	   opens of telos_ap channels. There are better ways, but it is
	   the simplest one.
	 */
	rtnl_lock();

	/* Collect hanged up channels. */
	telos_sync();

	telos = (struct telos_ap *) tty->disc_data;

	err = -EEXIST;
	/* First make sure we're not already connected. */
	if (telos && telos->magic == TELOS_AP_MAGIC)
		goto err_exit;

	/* OK.  Find a free TELOS_AP channel to use. */
	err = -ENFILE;
	if ((telos = telos_alloc(tty_devnum(tty))) == NULL)
		goto err_exit;

	telos->tty      = tty;
	tty->disc_data = telos;
	telos->line    = tty_devnum(tty);
	telos->pid     = current->pid;

	if (tty->driver->flush_buffer)
		tty->driver->flush_buffer(tty);
	if (tty->ldisc.flush_buffer)
		tty->ldisc.flush_buffer(tty);

	if (!test_bit(TELOSF_INUSE, &telos->flags)) {
		/* Perform the low-level TELOS_AP initialization. */
		if ((err = telos_alloc_bufs(telos, TELOS_MTU)) != 0)
			goto err_free_chan;

		set_bit(TELOSF_INUSE, &telos->flags);

		if ((err = register_netdevice(telos->dev)))
			goto err_free_bufs;
	}

	/* Done.  We have linked the TTY line to a channel. */
	rtnl_unlock();
	return telos->dev->base_addr;

err_free_bufs:
	telos_free_bufs(telos);

err_free_chan:
	telos->tty = NULL;
	tty->disc_data = NULL;
	clear_bit(TELOSF_INUSE, &telos->flags);

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

   By-product (not desired): telos? does not feel hangups and remains open.
   It is supposed, that user level program (dip, diald, slattach...)
   will catch SIGHUP and make the rest of work. 

   I see no way to make more with current tty code. --ANK
 */

/*
 * Close down a TELOS_AP channel.
 * This means flushing out any pending queues, and then restoring the
 * TTY line discipline to what it was before it got hooked to TELOS_AP
 * (which usually is TTY again).
 */
static void
telos_ap_close(struct tty_struct *tty)
{
	struct telos_ap *telos = (struct telos_ap *) tty->disc_data;

	// printk(KERN_WARNING "%s: %p\n", __FUNCTION__, telos);

	/* First make sure we're connected. */
	if (!telos || telos->magic != TELOS_AP_MAGIC || telos->tty != tty)
		return;

	tty->disc_data = NULL;
	telos->tty = NULL;
	telos->line = 0;

	/* Count references from TTY module */
}

static void
telos_ap_flush_buffer(struct tty_struct *tty)
{
	unsigned long flags;
	struct telos_ap *telos = (struct telos_ap *) tty->disc_data;
	
	spin_lock_irqsave(&tty->read_lock, flags);
	telos->read_queue_tail = telos->read_queue_head = 0;
	spin_unlock_irqrestore(&tty->read_lock, flags);
}

static ssize_t
telos_ap_chars_in_buffer(struct tty_struct *tty)
{
	unsigned long flags;
	struct telos_ap *telos = (struct telos_ap *) tty->disc_data;
	ssize_t n;

	spin_lock_irqsave(&tty->read_lock, flags);
	n = (TELOS_READ_QUEUE_DEPTH + telos->read_queue_head - telos->read_queue_tail) % TELOS_READ_QUEUE_DEPTH;
	n *= sizeof(telos->read_queue[0]);
	spin_unlock_irqrestore(&tty->read_lock, flags);
	
	return n;
}

static struct TelosInform *
telos_ap_pop_message( struct tty_struct *tty )
{
	struct telos_ap *telos = (struct telos_ap *) tty->disc_data;
	unsigned long flags;
	struct TelosInform *info = NULL;

	spin_lock_irqsave(&tty->read_lock, flags);
	if (telos->read_queue_head != telos->read_queue_tail) {
		info = telos->read_queue + telos->read_queue_tail;
		telos->read_queue_tail++;
		if ( telos->read_queue_tail >= TELOS_READ_QUEUE_DEPTH )
			telos->read_queue_tail = 0;
	}
	spin_unlock_irqrestore(&tty->read_lock, flags);
	return info;
}

static ssize_t
telos_ap_read(struct tty_struct *tty, struct file *file, unsigned char *buf, size_t nr)
{
	struct TelosInform *info;
	DECLARE_WAITQUEUE(wait, current);

	/* You must specify at least enough room for one buffer */
	if (nr < sizeof(*info))
		return -EIO;

	info = telos_ap_pop_message(tty);
	if ( !info ) {
		if (file->f_flags & O_NONBLOCK) 
			return -EAGAIN;

		add_wait_queue(&tty->read_wait, &wait);
	repeat:
		current->state = TASK_INTERRUPTIBLE;
		info = telos_ap_pop_message(tty);
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
telos_ap_poll(struct tty_struct *tty, struct file *file, struct poll_table_struct *wait)
{
	struct telos_ap *telos = (struct telos_ap *) tty->disc_data;

	poll_wait(file, &tty->read_wait, wait );
	if ( telos->read_queue_head != telos->read_queue_tail )
		return POLLIN | POLLRDNORM;

	return 0;
}

 /************************************************************************
  *			STANDARD TELOS_AP ENCAPSULATION		  	 *
  ************************************************************************/

int
telos_ap_esc(unsigned char *s, unsigned char *d, int len)
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
	 * character sequence, according to the TELOS_AP protocol.
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

static void telos_ap_unesc(struct telos_ap *telos, unsigned char s)
{
	// printk(KERN_WARNING "%s: %p\n", __FUNCTION__, telos);

	switch(s) {
	 case FRAME:
		if (!test_and_clear_bit(TELOSF_ERROR, &telos->flags) && (telos->rcount > 2))  {
			telos_bump(telos);
		}
		clear_bit(TELOSF_ESCAPE, &telos->flags);
		telos->rcount = 0;
		return;

	 case ESCAPE_BYTE:
		set_bit(TELOSF_ESCAPE, &telos->flags);
		return;
	}
	if (!test_bit(TELOSF_ERROR, &telos->flags))  {
		if (telos->rcount < telos->buffsize)  {
			if (test_and_clear_bit(TELOSF_ESCAPE, &telos->flags))
				telos->rbuff[telos->rcount++] = s ^ 0x20;
			else
				telos->rbuff[telos->rcount++] = s;
			return;
		}
		telos->rx_over_errors++;
		set_bit(TELOSF_ERROR, &telos->flags);
	}
}


/* Perform I/O control on an active TELOS_AP channel. */
static int telos_ap_ioctl(struct tty_struct *tty, struct file *file, unsigned int cmd, unsigned long arg)
{
	struct telos_ap *telos = (struct telos_ap *) tty->disc_data;

	/* First make sure we're connected. */
	if (!telos || telos->magic != TELOS_AP_MAGIC) {
		return -EINVAL;
	}

	switch(cmd) {
	case SIOCGDEVNAME:   // Assume buffer of size IFNAMSIZ
		if (copy_to_user((void *)arg, &telos->dev->name, IFNAMSIZ))
			return -EFAULT;
		return 0;
		
	case SIOCGRESET:
		return telos_send_reset(telos);
		/* Allow stty to read, but not set, the serial port */
	case TCGETS:
	case TCGETA:
		return n_tty_ioctl(tty, file, cmd, arg);

	default:
		return -ENOIOCTLCMD;
	}
}

static struct tty_ldisc	telos_ldisc = {
	.owner 		 = THIS_MODULE,
	.magic 		 = TTY_LDISC_MAGIC,
	.name 		 = "telos_ap",
	.open 		 = telos_ap_open,
	.close	 	 = telos_ap_close,
	.flush_buffer    = telos_ap_flush_buffer,
	.chars_in_buffer = telos_ap_chars_in_buffer,
	.read            = telos_ap_read,
	.ioctl		 = telos_ap_ioctl,
	.poll            = telos_ap_poll,
	.receive_buf	 = telos_ap_receive_buf,
	.receive_room	 = telos_ap_receive_room,
	.write_wakeup	 = telos_ap_write_wakeup,
};

static int __init telos_ap_init(void)
{
	int status;

	// printk(KERN_WARNING "%s\n", __FUNCTION__);

	if (telos_ap_maxdev < 4)
		telos_ap_maxdev = 4; /* Sanity */

	printk(KERN_INFO "TELOS_AP: version %s (dynamic channels, max=%d).\n",
	       TELOS_AP_VERSION, telos_ap_maxdev );
	telos_ap_devs = kmalloc(sizeof(struct net_device *)*telos_ap_maxdev, GFP_KERNEL);
	if (!telos_ap_devs) {
		printk(KERN_ERR "TELOS_AP: Can't allocate telos_ap devices array!  Uaargh! (-> No TELOS_AP available)\n");
		return -ENOMEM;
	}

	/* Clear the pointer array, we allocate devices when we need them */
	memset(telos_ap_devs, 0, sizeof(struct net_device *)*telos_ap_maxdev); 

	/* Fill in our line protocol discipline, and register it */
	//if ((status = tty_register_ldisc(N_TELOS_AP, &telos_ldisc)) != 0)  {
	if ((status = tty_register_ldisc(1, &telos_ldisc)) != 0)  {
		printk(KERN_ERR "TELOS_AP: can't register line discipline (err = %d)\n", status);
		kfree(telos_ap_devs);
	}
	return status;
}

static void __exit telos_ap_exit(void)
{
	int i;
	struct net_device *dev;
	struct telos_ap *telos;
	unsigned long timeout = jiffies + HZ;
	int busy = 0;

	// printk(KERN_WARNING "%s\n", __FUNCTION__);

	if (telos_ap_devs == NULL) 
		return;

	/* First of all: check for active disciplines and hangup them.
	 */
	do {
		if (busy) {
			set_current_state(TASK_INTERRUPTIBLE);
			schedule_timeout(HZ / 10);
		}

		busy = 0;
		for (i = 0; i < telos_ap_maxdev; i++) {
			dev = telos_ap_devs[i];
			if (!dev)
				continue;
			telos = dev->priv;
			spin_lock_bh(&telos->lock);
			if (telos->tty) {
				busy++;
				tty_hangup(telos->tty);
			}
			spin_unlock_bh(&telos->lock);
		}
	} while (busy && time_before(jiffies, timeout));


	for (i = 0; i < telos_ap_maxdev; i++) {
		dev = telos_ap_devs[i];
		if (!dev)
			continue;
		telos_ap_devs[i] = NULL;

		telos = dev->priv;
		if (telos->tty) {
			printk(KERN_ERR "%s: tty discipline still running\n",
			       dev->name);
			/* Intentionally leak the control block. */
			dev->destructor = NULL;
		} 

		unregister_netdev(dev);
	}

	kfree(telos_ap_devs);
	telos_ap_devs = NULL;

	// We steal SLIP
//	if ((i = tty_register_ldisc(N_TELOS_AP, NULL)))
	if ((i = tty_register_ldisc(1, NULL)))
	{
		printk(KERN_ERR "TELOS_AP: can't unregister line discipline (err = %d)\n", i);
	}
}

module_init(telos_ap_init);
module_exit(telos_ap_exit);

MODULE_LICENSE("GPL");
MODULE_ALIAS_LDISC(N_TELOS_AP);
