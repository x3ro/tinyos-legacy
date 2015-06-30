/*
 *  AP_CON - console-mode (command-line) program implemeting
 *           a simple 802.15.4 AP under Win32 (2000, XP, probably Vista)
 *
 *  This program is using/calling TAP-WIN32 GPL driver !!!
 *
 *  This source code is Copyright (C) 2008 Realtime Technologies
 *  and is released under the GPL version 2 (see below)
 *
 *  Portions of the code were inspired from ZATTACH.C and
 *  AccessPointApp (authors Andrew Christian <andrew.christian@hp.com>
 *	and Bor-rong Chen <bor-rong.chen@hp.com> )
 * 
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License version 2
 *  as published by the Free Software Foundation.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program (see the file COPYING included with this
 *  distribution); if not, write to the Free Software Foundation, Inc.,
 *  59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 *  Author: Caranfil Catalin <ccaranfil@shimmer-research.com>
 */ 


// AP_CON v0.4
// the application in this early stage is separated in 2 threads that would
// make possible future extensions or a full GUI version without a majore rewrite
// the configuration is coming from 802_15_4_AP.INI
// (created for the moment by another program)
// AP_CON talks to TAP-Win32 driver and to a COM port where a device (SHIMMER. Telos)
// running AccessPointApp from TinyOS should be present
// please see README.TXT on how TAP-Win32 driver is installed
// also please note that other than the fact that there is a kernel-mode part
// and a user-mode part the similarities with the Linux 802.15.4 AP are very
// limited since the kernel-mode part is VERY different in Windows !!!



#include "stdafx.h"

// stuff to build info about where program + INI are located
char g_path_file_ap[2048] = "";
char g_path_dir_ap[2048] = "";
char g_full_name_INI[2048] = "";

const char * g_name_INI = "802_15_4_AP.INI";

char g_ini_section[]	= "AP_WIN32";
char g_ini_adapter[]	= "ADAPTER_ID";
char g_ini_COM[]		= "COM_PORT";
char g_ini_flag_udp[]	= "FLAG_UDP";


//char g_name_adapter[256] = "{7976EB8A-9D81-4026-BCF9-9D3DEE8DB83D}";
char g_name_adapter[256] = "";

//char g_name_COM[256] = "COM6";
//char g_name_COM[256] = "COM7";
char g_name_COM[256] = "";

// this flag should be later extended
// probably with a list of UDP ports that should be avoided
volatile bool g_flag_udp = false;

bool verbose = true;



// the flag is used for a very quick check and should be set first
volatile bool g_flag_exit = false;
// the event should be signaled after setting the flag to exit from wait functions
HANDLE g_he_exit	= 0;

HANDLE g_he_comm_r	= 0;
HANDLE g_he_comm_w	= 0;
HANDLE g_he_adapt_r	= 0;
HANDLE g_he_adapt_w	= 0;

volatile HANDLE g_h_comm = 0;
volatile HANDLE g_h_comm_thread = 0;
volatile DWORD g_id_comm_thread = 0;

static HANDLE g_h_adapt = 0;


struct telos_ap g_telos = { 0 };

// comm buffer size
#define BSIZE 4100



inline void memswap(void * pv1, void * pv2, int len)
	{
	register BYTE * p1 = (BYTE *) pv1;
	register BYTE * p2 = (BYTE *) pv2;
	while(len-- > 0)
		{
		register BYTE b = * p1;
		*p1++ = *p2;
		*p2++ = b;
		}
	}


struct ARP_INFO
	{
    MACADDR        MAC;
    IPADDR         IP;
    
    ARP_INFO(void * p_mac, void * p_ip)
		{
		if(p_mac)
			{
			memcpy(MAC, p_mac, sizeof(MAC));
			}
		else
			{
			memset(MAC, 0, sizeof(MAC));
			}
		if(p_ip)
			{
			memcpy(&IP, p_ip, sizeof(IP));
			}
		else
			{
			memset(&IP, 0, sizeof(IP));
			}
		};
    };


struct less_ARP_INFO : public binary_function<ARP_INFO & , ARP_INFO & , bool> 
	{
    bool operator()(const ARP_INFO & x, const ARP_INFO &  y) const
		{
		return x.IP < y.IP;
		}
    };

typedef set<ARP_INFO, less_ARP_INFO> set_ARP_INFO;


set_ARP_INFO g_set_ARP_INFO;

bool ip_to_mac(void * p_ip, void * p_mac)
	{ 
	ARP_INFO ai(0, p_ip);
	set_ARP_INFO::iterator it = g_set_ARP_INFO.find(ai);
	if(it != g_set_ARP_INFO.end())
		{
		memcpy(p_mac, it->MAC, sizeof(MACADDR));
		return true;
		}
	return false;
	}




 /************************************************************************
  *			STANDARD TELOS_AP ENCAPSULATION		  	 *
  ************************************************************************/


inline bool test_and_clear_bit(BYTE bit_count, void * pv)
	{
	BYTE * p = (BYTE*)pv;
	BYTE b = *p;
	BYTE m = 1 >> bit_count;
	bool r = b & m;
	*p = b & (~m);
	return r;
	}

inline bool test_bit(BYTE bit_count, void * pv)
	{
	BYTE * p = (BYTE*)pv;
	BYTE b = *p;
	BYTE m = 1 >> bit_count;
	bool r = b & m;
	return r;
	}


inline void clear_bit(BYTE bit_count, void * pv)
	{
	BYTE * p = (BYTE*)pv;
	BYTE b = *p;
	BYTE m = 1 >> bit_count;
	*p = b & (~m);
	}

inline void set_bit(BYTE bit_count, void * pv)
	{
	BYTE * p = (BYTE*)pv;
	BYTE b = *p;
	BYTE m = 1 >> bit_count;
	*p = b | m;
	}





static int
telos_alloc_bufs(struct telos_ap *telos, int mtu)
{
	int err = -1;
	unsigned long len;
	char * rbuff = NULL;
	char * xbuff = NULL;

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

	rbuff = (char *) malloc(len + 4);
	if (rbuff == NULL)
		goto err_exit;
	xbuff = (char *) malloc(len + 4);
	if (xbuff == NULL)
		goto err_exit;
/*
	spin_lock_bh(&telos->lock);
	if (telos->tty == NULL) {
		spin_unlock_bh(&telos->lock);
		err = -ENODEV;
		goto err_exit;
	}
*/
	telos->mtu	    = mtu;
	telos->buffsize = len;
	telos->rcount   = 0;
	telos->xleft    = 0;
	rbuff = (char*) InterlockedExchangePointer(&telos->rbuff, rbuff);
	xbuff = (char*) InterlockedExchangePointer(&telos->xbuff, xbuff);
//	spin_unlock_bh(&telos->lock);
	err = 0;

	/* Cleanup */
err_exit:
	if (xbuff)
		free(xbuff);
	if (rbuff)
		free(rbuff);
	return err;
}

/* Free a TELOS_AP channel buffers. */
static void
telos_free_bufs(struct telos_ap *telos)
{
	void * tmp;

	// printk(KERN_WARNING "%s: %p\n", __FUNCTION__, telos);

	/* Free all TELOS_AP frame buffers. */
	if ((tmp = InterlockedExchangePointer(&telos->rbuff, NULL)) != NULL)
		free(tmp);
	if ((tmp = InterlockedExchangePointer(&telos->xbuff, NULL)) != NULL)
		free(tmp);
}



char * g_event_names[]=
	{
	"INFORM_EVENT_RESET",
	"INFORM_EVENT_ASSOCIATE",
	"INFORM_EVENT_REASSOCIATE",
	"INFORM_EVENT_STALE",
	"INFORM_EVENT_RELEASED",
	"INFORM_EVENT_ARP",
	};


void do_ti_info(struct TelosInform * pti)
	{
	int i = pti->event;
	char * p = 0;
	char b[256];
	if(i >= 0 && i < SIZEOF(g_event_names))
		{
		p = g_event_names[i];
		}
	else
		{
		p = b;
		sprintf(b, "unknown event %02x !!!", i);
		}
	printf("%s\n", p);

	if ( verbose ) {
		SYSTEMTIME st;
		LARGE_INTEGER li;
		GetSystemTime(&st);

		if(i >= 0 && i < SIZEOF(g_event_names))
		{
			p = g_event_names[i];
		}
		else
		{
			p = b;
			sprintf(b, "unknown event %02x !!!", i);
		}
		printf("Event: %s\n", p);
		//printf("\nEvent: %s\n", g_event_names[pti->event]);
		printf("Time:  %02d-%02d-%4d %02d:%02d:%02d\n", st.wMonth, st.wDay, st.wYear, st.wHour, st.wMinute, st.wSecond );
		unsigned long ip = ntohl(pti->ip);
		printf("IP:    %d.%d.%d.%d\n", 
			ip >> 24,
			(ip & 0xff0000) >> 16,
			(ip & 0xff00) >> 8,
			(ip & 0xff));
		printf("Addr:  %02x:%02x:%02x:%02x:%02x:%02x:%02x:%02x\n",
			 pti->l_addr[0], pti->l_addr[1], pti->l_addr[2], pti->l_addr[3],
			pti->l_addr[4], pti->l_addr[5], pti->l_addr[6], pti->l_addr[7]);
		if ( pti->event ) {
			printf("SAddr: %d\n", ntohs(pti->s_addr));
			printf("Flags: 0x%02x\n", pti->flags);
		}
		else {
			printf("PanID: 0x%04x\n", ntohs(pti->s_addr));
			//printf("Freq:  %d (channel %d)\n", ntohs(pti->frequency), freq_to_channel(ntohs(ti->frequency)));
			printf("SSID:  %s\n", pti->ssid);
		}
  }

  fflush(stdout);

	}



static void
telos_ap_add_message(struct telos_ap *telos, struct TelosInform *ti)
{
	//struct TelosInform *ti;
/*
	int n = (telos->read_queue_head + 1) % TELOS_READ_QUEUE_DEPTH;

	if ( n == telos->read_queue_tail ) {
//		printk("AP dropped message from client\n");
		return;
	}

	ti = telos->read_queue + telos->read_queue_head;
*/
	memset( ti, 0, sizeof(*ti));

	memcpy( &ti->ip, telos->rbuff+1, 4 );
	memcpy( &ti->l_addr, telos->rbuff+5, 8 );
	memcpy( &ti->s_addr, telos->rbuff+13, 2 );
	if ( telos->rbuff[0] == 0 ) {
		memcpy( &ti->frequency, telos->rbuff+15, 2 );
		strncpy( ti->ssid, (char*) telos->rbuff+17, sizeof(ti->ssid) );
	}
	else {
		ti->event = telos->rbuff[15];
		ti->flags = telos->rbuff[16];
	}
	
	do_ti_info(ti);
		
	//telos->read_queue_head = n;
	//wake_up_interruptible(&telos->tty->read_wait);
}




static void telos_bump(struct telos_ap *telos, unsigned char * p_dest)
	{
	// a new message is in the rcvd_buffer
	int count;

	count = telos->rcount;
	telos->rx_bytes += count;
	
	switch (telos->rbuff[0])
		{
	case TELOS_RESET:
		{
		printf("\nAP received reset message length %d\n", count );
/*
		printf("   ");
		int i;
		for(i = 0; i < count; ++i)
			{
			printf("%02x ", telos->rbuff[i]);
			}
		printf("\n\n");
		if(count != 21)
			{
			Sleep(0);
			}
*/
		//telos_ap_add_message( telos );
		}
		break;

	case TELOS_MESSAGE:
		printf("\nAP adding message length %d type %d\n", count, telos->rbuff[15]);
		struct TelosInform ti;
		telos_ap_add_message( telos, &ti);

		if(ti.event == INFORM_EVENT_ARP)
			{
			g_set_ARP_INFO.insert(ARP_INFO(ti.l_addr, &ti.ip));
	        //we should also send gratuitous arp !
			}

/*
		if(ti.event == INFORM_EVENT_ARP)
			{
			printf("   ");
			int i;
			for(i = 0; i < count; ++i)
				{
				printf("%02x ", telos->rbuff[i]);
				}
			printf("\n\n");
			if(count != 17)
				{
				Sleep(0);
				}
			}
*/
		break;
		
	case TELOS_DATA:
		//printf("\nAP received DATA message length %d\n", count - 1 );
		// here we should send data to adapter !
		// prepended with ETH_HEADER
		{
		BYTE data_adapt[BSIZE];
		ETH_HEADER * peth = (ETH_HEADER*) data_adapt;
		IPHDR * pip = (IPHDR*) (telos->rbuff + 1);
		ip_to_mac(&pip->daddr, peth->dest);
		ip_to_mac(&pip->saddr, peth->src);
		peth->proto = ETH_P_IP_host;
		memcpy(data_adapt + sizeof(ETH_HEADER), telos->rbuff + 1, count - 1);
		volatile DWORD n_adapt = 0;
		OVERLAPPED o_adapt;
		memset(&o_adapt, 0, sizeof(o_adapt));
		o_adapt.hEvent = g_he_adapt_w;
		BOOL b_adapt = WriteFile(g_h_adapt, &data_adapt, count - 1 + sizeof(ETH_HEADER), (DWORD*) &n_adapt, &o_adapt);
		DWORD m = 0;
		GetOverlappedResult(g_h_adapt, &o_adapt, &m, TRUE);
		ResetEvent(g_he_adapt_w);
		}

		
/*
		// Encapsulated IP data packet
//		printk("AP DATA packet\n");
		skb = dev_alloc_skb(count);
		if (skb == NULL)  {
			printk(KERN_WARNING "%s: memory squeeze, dropping packet.\n", telos->dev->name);
			telos->rx_dropped++;
			return;
		}
		skb->dev = telos->dev;
		memcpy(skb_put(skb,count - 1), telos->rbuff + 1, count - 1);

#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,21)		
		skb->mac_header=skb->data;
#else		
		skb->mac.raw=skb->data;
#endif
		skb->protocol=htons(ETH_P_IP);
		netif_rx(skb);
*/
		break;

	case TELOS_RESPONSE:
		// Response to a request
		break;
		}

//	telos->dev->last_rx = jiffies;
	telos->rx_packets++;

	if(p_dest && count < BSIZE)
		{
		memcpy(p_dest, telos->rbuff, count);
		}
	}



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

static int telos_ap_unesc(struct telos_ap *telos, unsigned char s, unsigned char * p_dest)
	{
	// printk(KERN_WARNING "%s: %p\n", __FUNCTION__, telos);

	switch(s)
		{
	case FRAME:
		{
		int rval = -1;
		if (!test_and_clear_bit(TELOSF_ERROR, &telos->flags) && (telos->rcount > 2)) 
			{
			telos_bump(telos, p_dest);
			rval = - (telos->rcount) ;
			}
		clear_bit(TELOSF_ESCAPE, &telos->flags);
		telos->rcount = 0;
		return rval;
		}

	case ESCAPE_BYTE:
		{
		set_bit(TELOSF_ESCAPE, &telos->flags);
		return -1;
		}
		
		}// end switch
	
	bool b_err = test_bit(TELOSF_ERROR, &telos->flags);
	if(b_err)
		{
		printf("\nTELOSF_ERROR\n");
		}
	if (!b_err)
		{
		if (telos->rcount < telos->buffsize)
			{
			unsigned char s2;
			if (test_and_clear_bit(TELOSF_ESCAPE, &telos->flags))
				{
				s2 = s ^ 0x20;
				}
			else
				{
				s2 = s;
				}
			telos->rbuff[telos->rcount++] = s2;
			return s2;
			}
		telos->rx_over_errors++;
		set_bit(TELOSF_ERROR, &telos->flags);
		return -1;
		}
	return -1;
	}






int init_adapter()
	{
	
	char device_path[1024];
	_snprintf(device_path, sizeof(device_path), "%s%s%s",
				USERMODEDEVICEDIR,
				g_name_adapter,
				TAPSUFFIX);

	g_h_adapt = CreateFile (	device_path,
								MAXIMUM_ALLOWED,
								0, /* was: FILE_SHARE_READ */
								0,
								OPEN_EXISTING,
								FILE_ATTRIBUTE_SYSTEM | FILE_FLAG_OVERLAPPED,
								0
								);

	if (g_h_adapt == INVALID_HANDLE_VALUE)
		{
		//msg (M_WARN, "CreateFile failed on TAP device: %s", device_path);
		return -1;
		}

	// test set connected
    DWORD status = TRUE;
    DWORD len;
    
    BOOL b = DeviceIoControl (g_h_adapt,
								TAP_IOCTL_SET_MEDIA_STATUS,
								&status, sizeof (status),
								&status, sizeof (status),
								&len, NULL) ;


	return 0;
	}


int release_adapter()
	{
	if(g_h_adapt)
		{
		CloseHandle(g_h_adapt);
		g_h_adapt = 0;
		}
	return 0;
	}




void dump_block(unsigned char * data_adapt, int count)
	{
	int i;
	for(i=0; i<count; ++i)
		{
		printf("%02x  ", data_adapt[i]);
		}
	printf("\n");
	}




unsigned __stdcall comm_thread(void * p)
	{
	SetThreadPriority(GetCurrentThread(), THREAD_PRIORITY_HIGHEST);

	//_set_se_translator(seh_trans_func);
	BYTE buff[1024];
	
	try
		{
		//SetThreadPriority(GetCurrentThread(), THREAD_PRIORITY_LOWEST);
		g_he_comm_r = CreateEvent(0, TRUE, FALSE, 0);
		g_he_comm_w = CreateEvent(0, TRUE, FALSE, 0);
		g_he_adapt_r = CreateEvent(0, TRUE, FALSE, 0);
		g_he_adapt_w = CreateEvent(0, TRUE, FALSE, 0);


		// send reset message to ap = one byte of zero
		{
		BYTE data[256] = { 0 };
		BYTE data_esc[256];
		DWORD n = telos_ap_esc(data, data_esc, 1);
		OVERLAPPED o_comm;
		memset(&o_comm, 0, sizeof(o_comm));
		o_comm.hEvent = g_he_comm_w;
		ResetEvent(g_he_comm_w);
		BOOL b = WriteFile(g_h_comm, &data_esc, n, (DWORD*) &n, &o_comm);
		DWORD m = 0;
		GetOverlappedResult(g_h_comm, &o_comm, &m, TRUE);
		ResetEvent(g_he_comm_w);
		//Sleep(0);
		}
		
		volatile bool done_comm = true;
		volatile bool done_adapt = true;
		BYTE data;
		DWORD n;
		OVERLAPPED o_comm;
		BYTE data_adapt[BSIZE];
		DWORD n_adapt;
		OVERLAPPED o_adapt;

		
		while(!g_flag_exit)
			{
			if(done_comm)
				{
				// init a new read
				done_comm = false;
				data = 0;
				n = 0;
				memset(&o_comm, 0, sizeof(o_comm));
				o_comm.hEvent = g_he_comm_r;
				BOOL b = ReadFile(g_h_comm, &data, 1, (DWORD*) &n, &o_comm);
				if(b)
					{
					//??
					SetEvent(g_he_comm_r);
					}
				}

			if(done_adapt)
				{
				// init a new read
				done_adapt = false;
				n_adapt = 0;
				memset(&o_adapt, 0, sizeof(o_adapt));
				o_adapt.hEvent = g_he_adapt_r;
				BOOL b_adapt = ReadFile(g_h_adapt, &data_adapt, BSIZE, (DWORD*) &n_adapt, &o_adapt);
				if(b_adapt)
					{
					//??
					SetEvent(g_he_adapt_r);
					}
				}
			

			volatile bool done = false;
			do
				{
				// build wait list
				HANDLE h_list[3];
				// first is event_exit
				h_list[0] = g_he_exit;
				// second is COMM port
				h_list[1] = g_he_comm_r;
				// thirs is TUN adapter
				h_list[2] = g_he_adapt_r;
				
				// wait
				DWORD rw = WaitForMultipleObjects(3, h_list, FALSE, 1);

				// check event exit
				if(rw == WAIT_OBJECT_0 + 0 )
					{
					return -1;
					}

				// check COMM
				if(rw == WAIT_OBJECT_0 + 1)
					{
					DWORD m = 0;
					GetOverlappedResult(g_h_comm, &o_comm, &m, TRUE);
					ResetEvent(g_he_comm_r);
					done = true;
					//printf("read from comm\n");
					//printf("%02x ", data);
					if(n == 1 || m == 1)
						{
						done_comm = true;
						BYTE b[BSIZE];
						int i = telos_ap_unesc(&g_telos, data, b);
						//printf("telos_rcount = %d\n", g_telos.rcount);
						//if(i >= 0)
						}
					else
						{
						printf("\nn=%d m=%d\n", n, m);
						}
					}
				
				// check event adapter
				if(rw == WAIT_OBJECT_0 + 2 )
					{
					DWORD m = 0;
					GetOverlappedResult(g_h_adapt, &o_adapt, &m, TRUE);
					ResetEvent(g_he_adapt_r);
					done = true;
					//printf("Event on adapter n=%d m=%d\n", n_adapt, m);
					int count = m + n;
					
					if(count > 0)
						{
						done_adapt = true;
						ETH_HEADER * peth = (ETH_HEADER*) data_adapt;
						if(peth->proto == ETH_P_ARP_host)
							{
							// check if worth dumping :)
							//dump_block(data_adapt, count);
							ARP_PACKET * parp = (ARP_PACKET*) data_adapt;
							if(parp->m_ARP_Operation == ARP_REQUEST_host)
								{
								if(parp->m_ARP_IP_Destination == parp->m_ARP_IP_Source)
									{
									// gratuitous ARP ?
									g_set_ARP_INFO.insert(ARP_INFO(parp->m_ARP_MAC_Source, &parp->m_ARP_IP_Source));
									}
								else
									{
									ARP_INFO ai(0, &parp->m_ARP_IP_Destination);
									set_ARP_INFO::iterator it = g_set_ARP_INFO.find(ai);
									if(it != g_set_ARP_INFO.end())
										{
										// we have the ARP answer and we should answer ...
										memswap(parp->m_ARP_MAC_Source, parp->m_ARP_MAC_Destination, sizeof(MACADDR) + sizeof(IPADDR));
										memcpy(parp->m_ARP_MAC_Source, it->MAC, sizeof(MACADDR));
										memswap(peth->src, peth->dest, sizeof(MACADDR));
										memset(&o_adapt, 0, sizeof(o_adapt));
										o_adapt.hEvent = g_he_adapt_w;
										BOOL b_adapt = WriteFile(g_h_adapt, &data_adapt, count, (DWORD*) &n_adapt, &o_adapt);
										m = 0;
										GetOverlappedResult(g_h_adapt, &o_adapt, &m, TRUE);
										ResetEvent(g_he_adapt_w);
										}
									}
								}
							} // ETH_P_ARP_host
						if(peth->proto == ETH_P_IP_host)
							{
							//dump_block(data_adapt, count);
							IPHDR * pip = (IPHDR *) (data_adapt + sizeof(ETH_HEADER));
							BYTE proto = pip->protocol;
							// ICMP TCP , UDP on flag
							if(proto == 1 || proto == 6 || (proto == 17 && g_flag_udp))
								{
								BYTE * p_data = data_adapt + sizeof(ETH_HEADER) - 1; // we leave room for 1 byte at start
								*p_data = TELOS_DATA;
								int len = count - sizeof(ETH_HEADER) + 1;
								BYTE data_esc[2100];
								n = telos_ap_esc(p_data, data_esc, len);
								DWORD nn = n;
								memset(&o_comm, 0, sizeof(o_comm));
								o_comm.hEvent = g_he_comm_w;
								ResetEvent(g_he_comm_w);
								BOOL b = WriteFile(g_h_comm, &data_esc, n, (DWORD*) &n, &o_comm);
								DWORD m = 0;
								GetOverlappedResult(g_h_comm, &o_comm, &m, TRUE);
								//printf("Sent %d bytes to AP\n", nn);
								//Sleep(1);
								}
							} // ETH_P_IP_host
						}
					} // adapter
				
				}
			while(!done);
			}
		}
	catch(...)
		{
		MessageBox(NULL,"catch(...) in com_thread!","802.15.4 ap ERROR!",MB_OK | MB_ICONWARNING | MB_DEFBUTTON1 | MB_SYSTEMMODAL);
		}
	
	release_adapter();
	CloseHandle(g_h_comm);
	CloseHandle(g_he_comm_r);
	CloseHandle(g_he_comm_w);
	CloseHandle(g_he_adapt_r);
	CloseHandle(g_he_adapt_w);
	return 0;
	}

/*
WaitCommEvent

*/




int start_com_thread()
	{
	// if already started
	if( g_h_comm_thread || g_h_comm)
		{
		return 1;
		}

	int ia = init_adapter();
	if(ia < 0)
		{
		return ia;
		}


	g_h_comm = CreateFile (	g_name_COM,
							GENERIC_READ | GENERIC_WRITE,
							0, /* was: FILE_SHARE_READ */
							0,
							OPEN_EXISTING,
							FILE_FLAG_OVERLAPPED, //FILE_ATTRIBUTE_SYSTEM | ,
							0
							);
	if(g_h_comm == INVALID_HANDLE_VALUE)
		{
		printf("could not open port %s ...\n", g_name_COM);
		//CloseHandle(hand);
		return -2;
		}

	BOOL fSuccess;

	COMMPROP com_prop = { 0 };
	fSuccess = GetCommProperties(g_h_comm, &com_prop);

	COMMTIMEOUTS com_time;
	fSuccess = GetCommTimeouts(g_h_comm, &com_time);
	
	fSuccess = SetupComm(g_h_comm, BSIZE, BSIZE);
	if(!fSuccess)
		{
		printf("could not SetupComm(%d,%d) ...\n", BSIZE, BSIZE);
		CloseHandle(g_h_comm);
		g_h_comm = 0;
		return -3;
		}



	DCB dcb;
	fSuccess = GetCommState(g_h_comm, &dcb);
	
	dcb.BaudRate	= CBR_57600; //CBR_115200;
	dcb.fDtrControl = DTR_CONTROL_DISABLE;
	dcb.fRtsControl = RTS_CONTROL_DISABLE;
	dcb.ByteSize	= 8;
	dcb.fParity		= 0;
	dcb.Parity		= NOPARITY;
	dcb.StopBits	= ONESTOPBIT;
	
	fSuccess = SetCommState(g_h_comm, &dcb);

	g_h_comm_thread = (HANDLE) _beginthreadex(NULL, 0x1000, comm_thread, NULL, 0, (unsigned *) &g_id_comm_thread);

	return 0;
	}





BOOL WINAPI CtrlHandler(DWORD fdwCtrlType) 
	{
	switch (fdwCtrlType) 
		{ 
	// Handle the CTRL+C signal.
	case CTRL_C_EVENT: 
	// also this
	case CTRL_BREAK_EVENT: 
		// signal to other worker threads
		g_flag_exit = true;
		SetEvent(g_he_exit);
		//Beep(1000, 1000); 
		printf("\nGot Control-C or Control-Break - exiting\n");
		return TRUE; 

	// CTRL+CLOSE: confirm that the user wants to exit. 
	case CTRL_CLOSE_EVENT: 
		// signal to other worker threads
		g_flag_exit = true;
		SetEvent(g_he_exit);
		//Beep(3000, 1000); 
		printf("\nConsole closed - exiting\n");
		return TRUE; 

	// Pass other signals to the next handler. 

	case CTRL_LOGOFF_EVENT: 

	case CTRL_SHUTDOWN_EVENT: 

	default: 
		return FALSE; 
		} 
	} 
  



int filename_to_pathname_x(char * buff)
	{
	if(buff == 0 || buff[0] == 0)
		{
		return -1;
		}
	char * last_slash = 0;
	char * p = buff;
	int i = 0;
	while(*p)
		{
		if(*p == '\\' || *p == '/')
			{
			last_slash = p;
			}
		p = CharNext(p);
		}
	last_slash = CharNext(last_slash);
	*last_slash = 0;
	return last_slash - buff;
	}



int init_main()
	{
	g_he_exit = CreateEvent(0, TRUE, FALSE, 0);
	if(g_he_exit == 0)
		{
		// fatal memory/handle error
		return -1;
		}
	
	if(telos_alloc_bufs(&g_telos, TELOS_MTU) != 0)
		{
		// memory error
		return -2;
		}

    BOOL fSuccess = SetConsoleCtrlHandler(CtrlHandler, TRUE);
    if (! fSuccess) 
		{
		printf("Could not set control handler !\n");
		return -3;
        }

	// build some info on our path and other files
	
	char buff[256];
	int len;
	
	GetModuleFileName(NULL, g_path_file_ap, SIZEOF(g_path_file_ap));
	strcpy(g_path_dir_ap ,g_path_file_ap);
	filename_to_pathname_x(g_path_dir_ap);

	SetCurrentDirectory(g_path_dir_ap);

	strcpy(g_full_name_INI, g_path_dir_ap);
	strcat(g_full_name_INI, g_name_INI);

	len = GetPrivateProfileString(g_ini_section, g_ini_adapter, "", buff, sizeof(buff), g_full_name_INI);
	if(len > 0)
		{
		strcpy(g_name_adapter, buff);
		}
	else
		{
		return -4;
		}

	len = GetPrivateProfileString(g_ini_section, g_ini_COM, "", buff, sizeof(buff), g_full_name_INI);
	if(len > 0)
		{
		strcpy(g_name_COM, buff);
		}
	else
		{
		return -5;
		}

	len = GetPrivateProfileString(g_ini_section, g_ini_flag_udp, "", buff, sizeof(buff), g_full_name_INI);
	if(len > 0)
		{
		int flag = 0;
		sscanf(buff, "%d", &flag);
		g_flag_udp = (flag != 0);
		}
	else
		{
		return -6;
		}


	//normal return 
	return 0;
	}




int _tmain(int argc, _TCHAR* argv[])
	{
	int i;

	SetPriorityClass(GetCurrentProcess(), HIGH_PRIORITY_CLASS);
	//SetThreadPriority(GetCurrentThread(), THREAD_PRIORITY_HIGHEST);
	
	i = init_main();
	if(i < 0)
		{
		printf("Error in init_main\n");
		return i - 100 ;
		}
		
	i = start_com_thread();
	if(i < 0)
		{
		printf("Error in start_com_thread\n");
		return i - 200 ;
		}

	printf("\nPress Control-C or Control-Break to exit\n");

	while(!g_flag_exit)
		{
		Sleep(1000);
		}

	//just in case
	g_flag_exit = true;
	SetEvent(g_he_exit);
	Sleep(1000);
	
	CloseHandle(g_he_exit);
	return 0;
	}
