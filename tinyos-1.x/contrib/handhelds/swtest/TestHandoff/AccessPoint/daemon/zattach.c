/*
 * Copyright (c) 2004,2005 Hewlett-Packard Company
 * All rights reserved
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:

 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *     * Neither the name of the Hewlett-Packard Company nor the names of its
 *       contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.

 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Connect the Telos mote via a line discipline to telos%d
 *
 * Based, in part on the 'hciattach' code.
 *
 * Andrew Christian <andrew.christian@hp.com>
 * 19 January 2005
 *
 * Added handling for device handoff
 *
 * Bor-rong Chen <bor-rong.chen@hp.com> 
 * 27 July 2005
 */

#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <getopt.h>
#include <signal.h>
#include <termios.h>
#include <unistd.h>

#include <sys/types.h>
#include <sys/socket.h>
#include <sys/utsname.h>
#include <sys/stat.h>
#include <fcntl.h>

#include <asm/ioctls.h>
#include <stdint.h>

#include <linux/if.h>
#include <linux/netlink.h>
#include <linux/rtnetlink.h>
#include <linux/sockios.h>

#include <netinet/in.h>
#include <netinet/udp.h>

#include "if_telos_ap.h"

static int g_verbose = 0;

struct rtnl_handle
{
  int                fd;      // The Netlink socket
  struct sockaddr_nl local;
  uint32_t           seq;
  int                index;   // Interface of the 'telosX' network
};

static struct rtnl_handle g_rth;

uint32_t g_my_ip = 0;
uint32_t g_bcast_ip = 0;

int dump_response(struct rtnl_handle *rth, char *devname)
{
  char  buf[8192];
  struct sockaddr_nl nladdr;
  struct iovec iov = { buf, sizeof(buf) };

  while (1) {
    int status;
    struct nlmsghdr *h;

    struct msghdr msg = {
      (void*)&nladdr, sizeof(nladdr),
      &iov, 1,
      NULL, 0,
      0
    };

    status = recvmsg(rth->fd, &msg, 0);

    if (status < 0) {
      if (errno == EINTR)
        continue;
      perror("OVERRUN");
      continue;
    }
    if (status == 0) {
      fprintf(stderr, "EOF on netlink\n");
      return -1;
    }
    if (msg.msg_namelen != sizeof(nladdr)) {
      fprintf(stderr, "sender address length == %d\n", msg.msg_namelen);
      exit(1);
    }

    h = (struct nlmsghdr*)buf;
    while (NLMSG_OK(h, status)) {
      int err;
      struct rtattr *rta;

      if ( h->nlmsg_seq != rth->seq )
        goto skip_it;

      if (h->nlmsg_type == NLMSG_DONE)
        return 0;

      if (h->nlmsg_type == NLMSG_ERROR) {
        struct nlmsgerr *err = (struct nlmsgerr*)NLMSG_DATA(h);
        if (h->nlmsg_len < NLMSG_LENGTH(sizeof(struct nlmsgerr))) {
          fprintf(stderr, "ERROR truncated\n");
        } else {
          errno = -err->error;
          perror("RTNETLINK answers");
        }
        return -1;
      }

      if (h->nlmsg_type == RTM_NEWLINK) {
        struct ifinfomsg *ifi = (struct ifinfomsg *) NLMSG_DATA(h);
        struct rtattr *rta;
        int len;

        if ( g_verbose > 1 )
          printf("info message family %d type %d index %d flags %u change %u\n", 
                 ifi->ifi_family, ifi->ifi_type, ifi->ifi_index, ifi->ifi_flags, ifi->ifi_change);

        rta = IFLA_RTA(ifi);
        len = IFLA_PAYLOAD(h);

        while (RTA_OK(rta,len)) {
          if ( g_verbose > 1) printf(" attribute type %d\n", rta->rta_type);
          if ( rta->rta_type == IFLA_IFNAME ) {
            if ( g_verbose > 1 ) printf("  interface name %s\n", RTA_DATA(rta));
            if ( strcmp(devname, RTA_DATA(rta)) == 0 )
              rth->index = ifi->ifi_index;
          }
          rta = RTA_NEXT(rta,len);
        }
        
      }

    skip_it:
      h = NLMSG_NEXT(h, status);
    }
    if (msg.msg_flags & MSG_TRUNC) {
      fprintf(stderr, "Message truncated\n");
      continue;
    }
    if (status) {
      fprintf(stderr, "!!!Remnant of size %d\n", status);
      exit(1);
    }
  }
}

static int dump_request( struct rtnl_handle *rth )
{
  struct {
    struct nlmsghdr nlh;
    struct rtgenmsg g;
  } req;
  struct sockaddr_nl nladdr;

  memset(&req, 0, sizeof(req));
  memset(&nladdr, 0, sizeof(nladdr));
  nladdr.nl_family = AF_NETLINK;

  req.nlh.nlmsg_len   = sizeof(req);
  req.nlh.nlmsg_type  = RTM_GETLINK;
  req.nlh.nlmsg_flags = NLM_F_ROOT|NLM_F_REQUEST;
  req.nlh.nlmsg_pid   = 0;
  req.nlh.nlmsg_seq   = ++rth->seq;
  req.g.rtgen_family  = AF_UNSPEC;

  if ( g_verbose > 1 ) printf("dump_request\n");
  return sendto(rth->fd, (void*)&req, sizeof(req), 0, (struct sockaddr*)&nladdr, sizeof(nladdr));
    return -1;
}

// This is the utility function for adding the parameters to the packet. 
static int addattr_l(struct nlmsghdr *n, int maxlen, int type, void *data, int alen) 
{ 
  int len = RTA_LENGTH(alen); 
  struct rtattr *rta; 

  if (NLMSG_ALIGN(n->nlmsg_len) + len > maxlen) 
    return -1; 
  
  rta = (struct rtattr*)(((char*)n) + NLMSG_ALIGN(n->nlmsg_len)); 
  rta->rta_type = type; 
  rta->rta_len = len; 
  memcpy(RTA_DATA(rta), data, alen); 
  n->nlmsg_len = NLMSG_ALIGN(n->nlmsg_len) + len; 
  return 0; 
}

static int set_host_address( struct rtnl_handle *rth, uint32_t ip )
{
  struct {
    struct nlmsghdr  nlh;
    struct ifaddrmsg g;
    char buf[256];
  } req;
  struct sockaddr_nl nladdr;

  memset(&req, 0, sizeof(req));
  memset(&nladdr, 0, sizeof(nladdr));
  nladdr.nl_family = AF_NETLINK;

  req.nlh.nlmsg_len   = NLMSG_LENGTH(sizeof(struct ifaddrmsg));
  req.nlh.nlmsg_type  = RTM_NEWADDR;
  req.nlh.nlmsg_flags = NLM_F_REQUEST|NLM_F_CREATE;   // Should this be REQUEST?
  req.nlh.nlmsg_pid   = 0;
  req.nlh.nlmsg_seq   = ++rth->seq;

  req.g.ifa_family    = AF_INET;
  req.g.ifa_prefixlen = 32;
  req.g.ifa_flags     = 0;
  req.g.ifa_scope     = 0;
  req.g.ifa_index     = rth->index;

  addattr_l(&req.nlh, sizeof(req), IFA_LOCAL, &ip, 4);
  addattr_l(&req.nlh, sizeof(req), IFA_ADDRESS, &ip, 4);

  if ( g_verbose ) printf("setting host ip address\n");
  //return sendto(rth->fd, (void*)&req, sizeof(req), 0, (struct sockaddr*)&nladdr, sizeof(nladdr));
  if (rtnl_talk(rth, &req.nlh, 0, 0, NULL, NULL, NULL) < 0)
    return -1;
}

#ifndef ZAP_PORT
#define ZAP_PORT 63331  
#endif

#define MAX_MSG_SIZE 100
#define INFORM_MSG_SIZE 4

/*
 *  Sends a broadcast notification UDP packet to inform other access points 
 *  about newly joined client
 *
 *  Packet format:
 *
 *       0      7 8     15 16    23 24    31 
 *      +--------+--------+--------+--------+
 *      |   associated device ip address    |
 *      +--------+--------+--------+--------+
 *
 */

static int zap_udp_notify(  int udpsockfd, uint32_t ip ) {

  char ubuf[INFORM_MSG_SIZE];
  int on = 1;

  struct sockaddr_in destaddr;

  memset(&destaddr, 0, sizeof(destaddr));
  destaddr.sin_family = AF_INET;
  destaddr.sin_addr.s_addr = g_bcast_ip;
  destaddr.sin_port = htons(ZAP_PORT);

  memset(&ubuf, 0, INFORM_MSG_SIZE);
  memcpy(&ubuf, &ip, INFORM_MSG_SIZE);

  fprintf(stderr, "sending UDP notification\n");
  if(sendto(udpsockfd, ubuf, sizeof(ubuf), 0, (struct sockaddr*) &destaddr, sizeof(destaddr)) == -1) {
    fprintf(stderr, "failed to send UDP notification, errno: %d ", errno);
    return -1;
  }

 return 0;
}

/* copied from iproute2 libnetlink.c */
int rtnl_talk(struct rtnl_handle *rtnl, struct nlmsghdr *n, pid_t peer,
              unsigned groups, struct nlmsghdr *answer,
              int (*junk)(struct sockaddr_nl *,struct nlmsghdr *n, void *),
              void *jarg)
{
        int status;
        unsigned seq;
        struct nlmsghdr *h;
        struct sockaddr_nl nladdr;
        struct iovec iov = { (void*)n, n->nlmsg_len };
        char   buf[8192];
        struct msghdr msg = {
                (void*)&nladdr, sizeof(nladdr),
                &iov,        1,
                NULL,        0,
                0
        };

        memset(&nladdr, 0, sizeof(nladdr));
        nladdr.nl_family = AF_NETLINK;
        nladdr.nl_pid = peer;
        nladdr.nl_groups = groups;

        n->nlmsg_seq = seq = ++rtnl->seq;
        if (answer == NULL)
                n->nlmsg_flags |= NLM_F_ACK;

        status = sendmsg(rtnl->fd, &msg, 0);

        if (status < 0) {
                perror("Cannot talk to rtnetlink");
                return -1;
        }

        iov.iov_base = buf;

        while (1) {
                iov.iov_len = sizeof(buf);
                status = recvmsg(rtnl->fd, &msg, 0);

                if (status < 0) {
                        if (errno == EINTR)
                                continue;
                        perror("OVERRUN");
                        continue;
                }
                if (status == 0) {
                        fprintf(stderr, "EOF on netlink\n");
                        return -1;
                }
                if (msg.msg_namelen != sizeof(nladdr)) {
                        fprintf(stderr, "sender address length == %d\n", msg.msg_namelen);
                        exit(1);
                }
                for (h = (struct nlmsghdr*)buf; status >= sizeof(*h); ) {
                        int err;
                        int len = h->nlmsg_len;
                        int l = len - sizeof(*h);

                        if (l<0 || len>status) {
                                if (msg.msg_flags & MSG_TRUNC) {
                                        fprintf(stderr, "Truncated message\n");
                                        return -1;
                                }
                                fprintf(stderr, "!!!malformed message: len=%d\n", len);
                                exit(1);
                        }

                        if (h->nlmsg_pid != rtnl->local.nl_pid ||
                            h->nlmsg_seq != seq) {
                                if (junk) {
                                        err = junk(&nladdr, h, jarg);
                                        if (err < 0)
                                                return err;
                                }
                                continue;
                        }

                        if (h->nlmsg_type == NLMSG_ERROR) {
                                struct nlmsgerr *err = (struct nlmsgerr*)NLMSG_DATA(h);
                                if (l < sizeof(struct nlmsgerr)) {
                                        fprintf(stderr, "ERROR truncated\n");
                                } else {
                                        errno = -err->error;
                                        if (errno == 0) {
                                                if (answer)
                                                        memcpy(answer, h, h->nlmsg_len);
                                                return 0;
                                        }
                                        if(g_verbose > 1)
                                        perror("RTNETLINK answers");
                                }
                                return -1;
                        }
                        if (answer) {
                                memcpy(answer, h, h->nlmsg_len);
                                return 0;
                        }

                        fprintf(stderr, "Unexpected reply!!!\n");

                        status -= NLMSG_ALIGN(len);
                        h = (struct nlmsghdr*)((char*)h + NLMSG_ALIGN(len));
                }
                if (msg.msg_flags & MSG_TRUNC) {
                        fprintf(stderr, "Message truncated\n");
                        continue;
                }
                if (status) {
                        fprintf(stderr, "!!!Remnant of size %d\n", status);
                        exit(1);
                }
        }
}

/*
struct rtmsg
{
	unsigned char		rtm_family;
	unsigned char		rtm_dst_len;
	unsigned char		rtm_src_len;
	unsigned char		rtm_tos;

	unsigned char		rtm_table;
	unsigned char		rtm_protocol;
	unsigned char		rtm_scope;
	unsigned char		rtm_type;

	unsigned		rtm_flags;
};*/


static int add_client_route( struct rtnl_handle *rth, uint32_t ip )
{
  struct {
    struct nlmsghdr  nlh;
    struct rtmsg     r;
    char buf[256];
  } req;
  struct sockaddr_nl nladdr;

  memset(&req, 0, sizeof(req));
  memset(&nladdr, 0, sizeof(nladdr));
  nladdr.nl_family = AF_NETLINK;

  req.nlh.nlmsg_len   = NLMSG_LENGTH(sizeof(struct rtmsg));
  req.nlh.nlmsg_type  = RTM_NEWROUTE;
  req.nlh.nlmsg_flags = NLM_F_REQUEST|NLM_F_CREATE|NLM_F_EXCL;
  req.nlh.nlmsg_pid   = 0;
  req.nlh.nlmsg_seq   = ++rth->seq;

  req.r.rtm_family    = AF_INET;
  req.r.rtm_dst_len   = 32; //destination legth in bits
  req.r.rtm_table     = RT_TABLE_MAIN;
  req.r.rtm_scope     = RT_SCOPE_UNIVERSE;
  req.r.rtm_protocol  = RTPROT_BOOT;
  req.r.rtm_type      = RTN_UNICAST;

  addattr_l(&req.nlh, sizeof(req), RTA_DST, &ip, 4 );
  addattr_l(&req.nlh, sizeof(req), RTA_OIF, &rth->index, 4 );

  if ( g_verbose ) printf("adding client route\n");
  if (rtnl_talk(rth, &req.nlh, 0, 0, NULL, NULL, NULL) < 0)
    return -1;

  return 0;
}

static int remove_client_route( struct rtnl_handle *rth, uint32_t ip )
{
  struct {
    struct nlmsghdr  nlh;
    struct rtmsg     r;
    char buf[256];
  } req;
  struct sockaddr_nl nladdr;

  memset(&req, 0, sizeof(req));
  memset(&nladdr, 0, sizeof(nladdr));
  nladdr.nl_family = AF_NETLINK;

  req.nlh.nlmsg_len   = NLMSG_LENGTH(sizeof(struct rtmsg));
  req.nlh.nlmsg_type  = RTM_DELROUTE;
  req.nlh.nlmsg_flags = NLM_F_REQUEST;
  req.nlh.nlmsg_pid   = 0;
  req.nlh.nlmsg_seq   = ++rth->seq;

  req.r.rtm_family    = AF_INET;
  req.r.rtm_dst_len   = 32; //destination legth in bits
  req.r.rtm_table     = RT_TABLE_MAIN;
  req.r.rtm_scope     = RT_SCOPE_NOWHERE;
  req.r.rtm_protocol  = RTPROT_BOOT;
  req.r.rtm_type      = RTN_UNICAST;

  addattr_l(&req.nlh, sizeof(req), RTA_DST, &ip, 4 );
  addattr_l(&req.nlh, sizeof(req), RTA_OIF, &rth->index, 4 );

  if (g_verbose) printf("deleting client route\n");
  if (rtnl_talk(rth, &req.nlh, 0, 0, NULL, NULL, NULL) < 0)
    return -1;

  return 0;
}

  static int netlink_open( struct rtnl_handle *rth )
  {
    int addr_len;
    memset(rth,0,sizeof(rth));

    /* Create a netlink socket */
    rth->fd = socket(AF_NETLINK, SOCK_DGRAM, NETLINK_ROUTE);
    if ( rth->fd < 0 ) {
      perror("Unable to create netlink socket");
      return -1;
    }

    rth->local.nl_family = AF_NETLINK;
    rth->local.nl_groups = 0;

    if ( bind(rth->fd, (struct sockaddr *)&rth->local, sizeof(rth->local)) < 0) {
      perror("Unable to bind socket");
      return -1;
    }

    addr_len = sizeof(rth->local);
    if (getsockname(rth->fd, (struct sockaddr *)&rth->local, &addr_len) < 0) {
      perror("Can't get sockname");
      return -1;
    }

    if ( addr_len != sizeof(rth->local)) {
      fprintf(stderr,"Wrong address length %d\n", addr_len);
      return -1;
    }

    if ( rth->local.nl_family != AF_NETLINK ) {
      fprintf(stderr, "Wrong address family %d\n", rth->local.nl_family);
      return -1;
    }

    rth->seq   = time(NULL);
    rth->index = -1;
  }

  static int bring_up_netlink(char *devname)
  {
  if ( netlink_open(&g_rth) < 0 )
    return -1;

  if ( dump_request(&g_rth) < 0 ) {
    perror("Unable to dump route table");
    return -1;
  }

  if ( dump_response(&g_rth, devname) < 0 ) {
    perror("Unable to dump response");
    return -1;
  }

  if ( g_rth.index >= 0 ) {
    if ( g_verbose > 1 ) printf("Matched index %d\n", g_rth.index);
  }
}

/**************************************************************************************/

/* 
 * Cribbed from iplink.c / iproute2 project 
 *
 * This routine sets the IFF_UP flag on a network device (like 'telos0')
 * which brings up the interface
 */

static int bring_up_interface( char *dev )
{
  uint32_t mask  = IFF_UP;
  uint32_t flags = IFF_UP;
  
  struct ifreq ifr;
  int fd;
  int err;

  fd = socket(PF_INET, SOCK_DGRAM, 0);
  if (fd < 0) {
    perror("Unable to create control socket");
    return -1;
  }

  strcpy(ifr.ifr_name, dev);

  err = ioctl(fd, SIOCGIFFLAGS, &ifr);
  if (err) {
    perror("SIOCGIFFLAGS");
    close(fd);
    return -1;
  }

  if ((ifr.ifr_flags^flags)&mask) {
    ifr.ifr_flags &= ~mask;
    ifr.ifr_flags |= mask&flags;
    err = ioctl(fd, SIOCSIFFLAGS, &ifr);
    if (err)
      perror("SIOCSIFFLAGS");
  }
  close(fd);
  return err;
}

/**************************************************************************************/

static int uart_speed(int s)
{
  switch (s) {
  case 1200:
    return B1200;
  case 2400:
    return B2400;
  case 4800:
    return B4800;
  case 9600:
    return B9600;
  case 19200:
    return B19200;
  case 38400:
    return B38400;
  case 57600:
    return B57600;
  case 115200:
    return B115200;
  case 230400:
    return B230400;
  case 460800:
    return B460800;
  case 921600:
    return B921600;
  default:
    return -1;
  }
}
 
static void setline(int fd, int flags, int speed)
{
  struct termios t;
  int result;
 
  result = tcgetattr(fd,&t);
  if (result) {
    perror("Unable to tcgetattr");
    exit(1);
  }

  t.c_cflag = flags | CREAD | HUPCL | CLOCAL;
  t.c_iflag = IGNBRK | IGNPAR;
  t.c_oflag = 0;
  t.c_lflag = 0;
  t.c_cc[VMIN ] = 1;
  t.c_cc[VTIME] = 0;
 
  cfsetispeed(&t, speed);
  cfsetospeed(&t, speed);
 
  tcsetattr(fd, TCSANOW, &t);
}
 
/*
 * Initialize the UART.
 * 
 * 1. Set the line discipline to N_SLIP....which is actually our telos_ap
 *    line discipline.
 * 
 * 2. Extract the network interface name from the line discipline (a custom
 *    ioctl supported by our line discipline.
 *
 * 3. Bring up the network interface
 * 
 * 4. Send a RESET ioctl to the line discipline. This sends a reset command
 *    across the serial port to the Zigbee access point.
 *
 */

static int init_uart(char *dev, int flags, int speed)
{
  int fd, i;
  char buf[100];

  fd = open(dev, O_RDWR | O_NOCTTY );
  if (fd < 0) {
    perror("Can't open serial port");
    return -1;
  }

  setline(fd, flags, speed);

  // Line discipline...currently N_SLIP
#ifndef N_TELOS_AP
#define N_TELOS_AP 1  
#endif

  i = N_TELOS_AP;   
  if (ioctl(fd, TIOCSETD, &i ) < 0) {
    perror("line disc");
    return -1;
  }

  if (ioctl(fd, SIOCGDEVNAME, buf) < 0 ) {
    perror("get device name");
    return -1;
  }

  if ( g_verbose ) printf("Device name %s\n", buf);
  bring_up_interface(buf);
  bring_up_netlink(buf);

  if (ioctl(fd, SIOCGRESET, 0) < 0 ) {
    perror("Reset");
    return -1;
  }

  return fd;
}

#define N_TTY 0
static void release_uart(int tty_fd)
{
  int ldisc = N_TTY;

  if (tcflush(tty_fd, TCIOFLUSH) < 0) {
    perror("Failed to flush");
  }

  if (ioctl(tty_fd, TIOCSETD, &ldisc) < 0) {
    perror("Failed to set tty_fd to N_TTY");
  }

  close(tty_fd);
}

static void usage(void)
{
  printf("zattach - Zigbee Access Point initialization\n");
  printf("Usage:\n");
  printf("\tzattach [-n] [-v] [-p] [-t timeout] [-b baudrate] TTY\n");
  printf("\tOptions:\t-n\tDo not detach process\n");
  printf("\t        \t-p\tPrint child process ID\n");
  printf("\t        \t-t NUM\tSet maximum timeout\n");
  printf("\t        \t-b RATE\tSet UART baud rate\n");
  printf("\t        \t-v\tIncrease verbosity (may be repeated)\n");
  exit(0);
}

static void sig_alarm(int sig)
{
  fprintf(stderr, "Initialization timed out.\n");
  exit(1);
}

static char *g_event[] = { "Reset", "Associate", "Re-Associate", "Stale", "Released", "ARP" };

static int freq_to_channel( uint16_t freq )
{
  return freq / 5 - 470;
}

static void print_event(struct TelosInform *ti)
{
  uint32_t ip = ntohl(ti->ip);

  printf("\nEvent: %s\n", g_event[ti->event]);
  printf("IP:    %d.%d.%d.%d\n", 
         ip >> 24,
         (ip & 0xff0000) >> 16,
         (ip & 0xff00) >> 8,
         (ip & 0xff));
  printf("Addr:  %02x:%02x:%02x:%02x:%02x:%02x:%02x:%02x\n",
         ti->l_addr[0], ti->l_addr[1], ti->l_addr[2], ti->l_addr[3],
         ti->l_addr[4], ti->l_addr[5], ti->l_addr[6], ti->l_addr[7]);
  if ( ti->event ) {
    printf("SAddr: %d\n", ntohs(ti->s_addr));
    printf("Flags: 0x%02x\n", ti->flags);
  }
  else {
    printf("PanID: 0x%04x\n", ntohs(ti->s_addr));
    printf("Freq:  %d (channel %d)\n", ntohs(ti->frequency), freq_to_channel(ntohs(ti->frequency)));
    printf("SSID:  %s\n", ti->ssid);
  }

  fflush(stdout);
}

#define MAX_DEV_NAME 32

#define inaddrr(x) (*(struct in_addr *) &ifr->x[sizeof sa.sin_port])
#define IFRSIZE   ((int)(size * sizeof (struct ifreq)))

int get_local_ip() {
  unsigned char      *u;
  int                sockfd, size  = 1;
  struct ifreq       *ifr;
  struct ifconf      ifc;
  struct sockaddr_in sa;

  if (0 > (sockfd = socket(AF_INET, SOCK_DGRAM, IPPROTO_IP))) {
   fprintf(stderr, "Cannot open socket.\n");
    exit(EXIT_FAILURE);
  }

  ifc.ifc_len = IFRSIZE;
  ifc.ifc_req = NULL;

  do {
    ++size;
    // realloc buffer size until no overflow occurs 
    if (NULL == (ifc.ifc_req = realloc(ifc.ifc_req, IFRSIZE))) {
      fprintf(stderr, "Out of memory.\n");
      exit(EXIT_FAILURE);
    }
    ifc.ifc_len = IFRSIZE;
    if (ioctl(sockfd, SIOCGIFCONF, &ifc)) {
      perror("ioctl SIOCFIFCONF");
      exit(EXIT_FAILURE);
    }
  } while  (IFRSIZE <= ifc.ifc_len);

  ifr = ifc.ifc_req;
  for (;(char *) ifr < (char *) ifc.ifc_req + ifc.ifc_len; ++ifr) {

    if (ifr->ifr_addr.sa_data == (ifr+1)->ifr_addr.sa_data) {
      continue;  // duplicate, skip it 
    }

    if (ioctl(sockfd, SIOCGIFFLAGS, ifr)) {
      continue;  // failed to get flags, skip it
    }

    //find the interface that is up and have broadcast support
    if ((ifr->ifr_flags & IFF_UP) && (ifr->ifr_flags & IFF_BROADCAST)) {
      memcpy(&g_my_ip, &ifr->ifr_addr.sa_data[sizeof(sa.sin_port)], sizeof(g_my_ip));
      fprintf(stderr,"Local Ethernet Interface Info:\n");
      fprintf(stderr,"Interface name:  %s\n", ifr->ifr_name);
      fprintf(stderr,"IP Address: %s\n", inet_ntoa(inaddrr(ifr_addr.sa_data)));

      if (0 == ioctl(sockfd, SIOCGIFBRDADDR, ifr))
      {
        memcpy(&g_bcast_ip, &ifr->ifr_addr.sa_data[sizeof(sa.sin_port)], sizeof(g_bcast_ip));
        printf("Broadcast:  %s\n", inet_ntoa(inaddrr(ifr_addr.sa_data)));
      }

      return 0;
    } 
    printf("\n");
  }

  close(sockfd);
  return -1;
}


int main(int argc, char *argv[])
{
  int opt, i, fd, n;
  int detach   = 1;
  int printpid = 0;
  int timeout  = 5;
  pid_t pid;
  char dev[MAX_DEV_NAME];
  struct sigaction sa;
  int speed = B57600;
  int flags = CS8;

  //for UDP communication
  int udpfd, nready, maxfdp1, n_rcv, on;
  struct sockaddr_in servaddr, cliaddr;
  fd_set rset;
  socklen_t len;

  char mesg[MAX_MSG_SIZE];
  
  while ((opt=getopt(argc,argv, "npt:vb:")) != EOF) {
    switch (opt) {
    case 'n': 
      detach = 0;
      break;
    case 'p':
      printpid = 1;
      break;
    case 'b':
      speed = uart_speed(atoi(optarg));
      if ( speed < 0 ) {
        fprintf(stderr,"Unrecognized baud rate %d\n",atoi(optarg));
        usage();
      }
      break;
    case 't':
      timeout = atoi(optarg);
      break;
    case 'v':
      g_verbose++;
      break;
    default:
      usage();
    }
  }

  n = argc - optind;
  if (n != 1)
    usage();

  dev[0] = 0;
  if (!strchr(argv[optind], '/'))
    strcpy(dev,"/dev/");
  strncat(dev,argv[optind],MAX_DEV_NAME - strlen(dev));

  memset(&sa,0,sizeof(sa));
  sa.sa_flags = SA_NOCLDSTOP;
  sa.sa_handler = sig_alarm;
  sigaction(SIGALRM, &sa, NULL);

 //bring up the telos device
  alarm(timeout);
  fd = init_uart(dev, flags, speed);
  if ( fd < 0 ) {
    perror("Can't initialize device");
    exit(1);
  }
  alarm(0);

  if (detach) {
    if ((pid = fork())) {
      if (printpid)
        printf("%d\n", pid);
      return 0;
    }
    for (i=0 ; i<20 ; i++)
      if (i != n)
        close(i);
  }

  //bind at ZAP_PORT for communication among access points
  if((udpfd = socket(AF_INET, SOCK_DGRAM, 0)) == -1) {
    perror("Can't allocate a socket for UDP binding");
    exit(1);
  }

  //enable broadcast on this socket
  on = 1;
  setsockopt(udpfd, SOL_SOCKET, SO_BROADCAST, &on, sizeof(on));

  if( g_verbose )
    fprintf(stderr, "got socket for binding: %d\n", udpfd);

  memset(&servaddr, 0, sizeof(servaddr));
  servaddr.sin_family = AF_INET;
  servaddr.sin_addr.s_addr = htonl(INADDR_ANY);
  servaddr.sin_port = htons(ZAP_PORT);

  if(bind(udpfd, (struct sockaddr*) &servaddr, sizeof(servaddr)) == -1) {
    fprintf(stderr, "Can't bind to ZAP_PORT: %d\n", ZAP_PORT);
    exit(1);
  }

  if( g_verbose )
    fprintf(stderr, "binding success!\n", udpfd);

  FD_ZERO(&rset);

  if(fd > udpfd) {
    maxfdp1 = fd + 1;
  } else {
    maxfdp1 = udpfd + 1;
  }

  get_local_ip();

  while (1) {
    FD_SET(fd, &rset);
    FD_SET(udpfd, &rset);

    if ( (nready = select(maxfdp1, &rset, NULL, NULL, NULL)) < 0) {
      if (errno == EINTR)
        continue;    /* back to while() */
      else {
        perror("select error");
        exit(1);
      }
    }

   if (FD_ISSET(udpfd, &rset)) {

      uint32_t dev_ip;
      uint32_t cli_ip;
      struct sockaddr_in my_addr;
      int my_addr_len;

      len = sizeof(cliaddr);
      n_rcv = recvfrom(udpfd, mesg, MAX_MSG_SIZE, 0, (struct sockaddr *) &cliaddr, &len);
      if(g_verbose > 1)
       fprintf(stderr,"received UDP notification: size: %d\n", n_rcv);

      if(n_rcv>0) {
        memcpy(&dev_ip, mesg, sizeof(dev_ip));
        memcpy(&cli_ip, &cliaddr.sin_addr, sizeof(cli_ip));

        if(g_verbose > 1)
          fprintf(stderr,"received UDP notification: IP: %d.%d.%d.%d\n", 
            (dev_ip & 0xff),
            (dev_ip & 0xff00) >> 8,
            (dev_ip & 0xff0000) >> 16,
            dev_ip >> 24);
  
        if(g_verbose > 1)
          fprintf(stderr,"from IP: %d.%d.%d.%d\n", 
            (cli_ip & 0xff),
            (cli_ip & 0xff00) >> 8,
            (cli_ip & 0xff0000) >> 16,
            cli_ip >> 24);

        if(cli_ip != g_my_ip){
            remove_client_route( &g_rth, dev_ip );
            if(g_verbose)
              fprintf(stderr, "remove route entry for re-connected device\n");
        }
      }
    }

    if (FD_ISSET(fd, &rset)) {
      struct TelosInform ti;
      n = read( fd, &ti, sizeof(ti) );
      if ( n < 0 ) {
        perror("Can't read");
        exit(1);
      }

      if ( g_verbose ) print_event(&ti);

      switch (ti.event) {
      case INFORM_EVENT_RESET:
        set_host_address( &g_rth, ti.ip );
        break;

      case INFORM_EVENT_ARP:
        add_client_route( &g_rth, ti.ip );
        zap_udp_notify( udpfd, ti.ip );
        break;

      case INFORM_EVENT_RELEASED:
        if (ti.ip) {
        remove_client_route( &g_rth, ti.ip );
        }
      }
    }
 }

  return 0;
}
