/**
 * Copyright (c) 2005 Hewlett-Packard Company
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
 *
 *  Information Memory storage of key device attributes.
 *
 *  We store a block of data in the information memory section
 *  of the MSP flash (0x1000-0x10ff).  This block is programmed
 *  when the device is programmed, but may be modified later on
 *  using standard tools.
 *
 *  To retrieve and examine this block, you can use:
 *
 *  For USB-loaded devices:
 *    msp430-bsl --telos --password=main.exe --upload 4096 --size 256 -c /dev/ttyUSBx
 *
 *  For JTAG-loaded devices:
 *    msp430-jtag -u 0x1000 -s 0x100
 *
 *  Note that the bsl program requires a password, which is really just the
 *  copy of the executable file that is already loaded into the device.
 *  Don't forget to reset your BSL-based device after running this.
 *
 *  Author:  Andrew Christian <andrew.christian@hp.com>
 *           April 2005
 *
 */

#ifndef __INFO_MEM_H
#define __INFO_MEM_H

struct InfoMem {
  uint16_t version;  // High byte = major version, low byte = minor
  uint8_t  mac[8];   // Radio MAC address
  uint8_t  ip[4];    // IP Address
  uint8_t  ssid[16]; // Radio SSID.  Must be null-terminated
  uint16_t pan_id;   // 802.15.4 default Pan ID.  Used by Access points.
  uint8_t  registrar_ip[4];     // IP address of the registrar
  uint16_t registrar_port;      // TCP/IP port of the registrar
  uint8_t  ntp_ip[4];           // IP address of the NTP server
  int      gmt_offset_minutes;  // Current offset (in minutes) from GMT
};

#define IM_VERSION   0x0101    // 1.1 

#ifndef LONG_ADDRESS
#define LONG_ADDRESS 0x0001
#endif
#define MAC_ADDRESS  0xa0, 0xa0, 0x00, 0x00, 0x00, 0x00, ((LONG_ADDRESS) >> 8), (LONG_ADDRESS) & 0xff 

#ifndef IP
#define IP   10,0,1,1
#endif

#ifndef SSID
#define SSID "CRL-Medical"
#endif

#ifndef PAN_ID
#define PAN_ID 0xbeef
#endif

#ifndef REGISTRAR_IP
#define REGISTRAR_IP 0,0,0,0
#endif

#ifndef REGISTRAR_PORT
#define REGISTRAR_PORT 4111
#endif

#ifndef NTP_IP
#define NTP_IP 255,255,255,255
#endif

#ifndef GMT_OFFSET_MINUTES
#define GMT_OFFSET_MINUTES  4 * 60       // EDT is 4 hours after GMT.  EST is 5 hours after GMT
#endif

/* 
 * The g_infomem structure is placed into the section ".infomem"
 *
 * If you don't want to have it programmed by default, put it in
 * the section ".infomemnobits".  However, the standard BSL and JTAG
 * tools erase all of memory by default, so be careful when updating
 * your software.
 *
 * If you need the information memory for some other purpose, you
 * can always put it in section ".text" 
 *
 * We always access the g_infomem structure through the infomem
 * pointer.  In the future we may wish to dynamically assign this pointer
 * at start up.
 */

struct InfoMem __attribute__((section(".infomem"))) g_infomem = {
  IM_VERSION,
  { MAC_ADDRESS },
  { IP },
  SSID,
  PAN_ID,
  { REGISTRAR_IP },
  REGISTRAR_PORT,
  { NTP_IP },
  GMT_OFFSET_MINUTES
};

const struct InfoMem * const infomem = &g_infomem;

#endif
