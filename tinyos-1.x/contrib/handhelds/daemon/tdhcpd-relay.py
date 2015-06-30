#!/usr/bin/python
'''

   Copyright (c) 2005 Hewlett-Packard Company
   All rights reserved

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions are
   met:

      * Redistributions of source code must retain the above copyright
         notice, this list of conditions and the following disclaimer.
      * Redistributions in binary form must reproduce the above
         copyright notice, this list of conditions and the following
         disclaimer in the documentation and/or other materials provided
         with the distribution.
      * Neither the name of the Hewlett-Packard Company nor the names of its
         contributors may be used to endorse or promote products derived
         from this software without specific prior written permission.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
   A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
   OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
   LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
   DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
   THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
   (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
   OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

'''

from twisted.internet import protocol, reactor, error, defer, interfaces, address
from twisted.python import failure, components

from socket import *
import sys
import struct
import string
import getopt

config = { 'verbose' : 0,
           'bootps'  : 1,
           'bootpc'  : 0,
           'ipaddr'  : None }

s = socket(AF_INET, SOCK_DGRAM)

DHCPDISCOVER	= 1
DHCPOFFER	= 2
DHCPREQUEST	= 3
DHCPDECLINE	= 4
DHCPACK		= 5
DHCPNAK		= 6
DHCPRELEASE	= 7
DHCPINFORM	= 8

OPTION_SUBNET_MASK       = 1
OPTION_TIME_OFFSET       = 2 ## subnet's offset in seconds from UTC
OPTION_ROUTER_OPTION     = 3 
OPTION_DNS_SERVERS       = 6
OPTION_HOST_NAME         = 12 ## host name of client
OPTION_DOMAIN_NAME       = 15 ## domain name of client
OPTION_BROADCAST_ADDRESS = 28
OPTION_STATIC_ROUTES     = 33
OPTION_ARP_CACHE_TIMEOUT = 35 ## in seconds
OPTION_NTP_SERVERS       = 42
OPTION_LEASE_TIME        = 51
OPTION_DHCP_MESSAGE_TYPE = 53
OPTION_SERVER_IDENTIFIER = 54
OPTION_PARAMETER_LIST    = 55
OPTION_MESSAGE           = 56 ## for debug messages
OPTION_CLIENT_IDENTIFIER = 61
OPTION_TFTP_SERVERS      = 66
OPTION_SMTP_SERVERS      = 69
OPTION_TIMEZONE          = 88 ## http://www.iana.org/assignments/bootp-dhcp-extensions/bootp-dhcp-option-88
OPTION_MDHCP             = 101 ## multicast group allocation http://www.iana.org/assignments/bootp-dhcp-extensions/bootp-dhcp-option-101
OPTION_URL               = 112 ## http://www.iana.org/assignments/bootp-dhcp-extensions/bootp-dhcp-option-114
OPTION_SIP_SERVERS       = 120
OPTION_END_OPTIONS       = 255

parameter_request_list = struct.pack('BBBBBBBB', OPTION_PARAMETER_LIST, 6,
                                     OPTION_DNS_SERVERS, OPTION_DOMAIN_NAME, OPTION_HOST_NAME,
                                     OPTION_NTP_SERVERS, OPTION_LEASE_TIME, OPTION_TIMEZONE)
client_requests = {}

##
## when we receive TDHCP request, send DHCPDISCOVER, wait for DHCPOFFER, send DHCPREQUEST, wait for DHCPACK, send TDHCP response
##

class DHCPRequest:
    def __init__(self, mtype, htype, hlen, hops, xid, secs, flags, ciaddr, yiaddr, siaddr, giaddr, chaddr):
        self.mtype = mtype
        self.htype = htype
        self.hlen = hlen
        self.hops = hops
        self.xid = xid
        self.secs = secs
        self.flags = flags
        self.ciaddr = ciaddr
        self.yiaddr = yiaddr
        self.siaddr = siaddr
        self.giaddr = giaddr
        self.chaddr = chaddr
        self.ntpaddr = struct.pack('4s', '')
        self.options = {}
        return
    def parseOptions(self, options):
        magic_cookie_bytes = options[0:3]
        options = options[4:]
        while len(options) > 0:
            option = ord(options[0])
            if option == OPTION_END_OPTIONS:
                return
            optionlen = ord(options[1])
            optionbytes = options[0:2+optionlen]
            if config['verbose']: print '  Option: %s' % string.join(["%02x" % ord(x) for x in optionbytes], ' ')
            if option == OPTION_DHCP_MESSAGE_TYPE:
                self.options[option] = ord(options[2])
            elif option == OPTION_SERVER_IDENTIFIER:
                self.options[option] = struct.unpack('!L', options[2:6])
            elif option == OPTION_LEASE_TIME:
                self.options[option] = struct.unpack('!L', options[2:6])
            elif option == OPTION_DNS_SERVERS:
                self.options[option] = struct.unpack('!L', options[2:6])
            elif option == OPTION_NTP_SERVERS:
                self.options[option] = struct.unpack('!L', options[2:6])
                self.ntpaddr = options[2:6]
            elif option == OPTION_DOMAIN_NAME:
                if config['verbose']: print '   Domain Name: %s' % optionbytes[2:]
                self.options[option] = optionbytes[2:]
            elif option == OPTION_HOST_NAME:
                if config['verbose']: print '   Host Name: %s' % optionbytes[2:]
                self.options[option] = optionbytes[2:]
            elif option == OPTION_SIP_SERVERS:
                optionlen = ord(options[1])
                encoding = ord(options[2])
                if encoding == 1:
                    ## contains dns-encoded name of sip servers
                    sipserver = ''
                    sep = ''
                    suboption = options[3:2+optionlen]
                    while len(suboption) > 0:
                        componentlen = ord(suboption[0])
                        component = suboption[1:1+componentlen]
                        sipserver = sipserver + sep + component
                        sep = '.'
                        suboption = suboption[1+componentlen:]
                    self.options[option] = sipserver
                else:
                    ## grab first address
                    self.options[option] = struct.unpack('!L', options[3:7])
            optionlen = ord(options[1])
            options = options[2+optionlen:]
        return

class DHCPServer(protocol.DatagramProtocol):
    def sendTDHCPResponse(self, req):
        if config['verbose']: print 'sending tdhcp request sent'
        msg = struct.pack('!bbbblHHLLLL', 2, req.htype, req.hlen, req.hops, req.xid, req.secs, req.flags,
                          req.ciaddr, req.yiaddr, req.siaddr, req.giaddr, req.ntpaddr)
        orig_ciaddrstr = inet_ntop(AF_INET,  struct.pack('!L', req.orig_ciaddr))
        if config['verbose']: print ('orig_ciaddrstr', orig_ciaddrstr, 168)
        tdhcp_port.write(msg, (orig_ciaddrstr, 168))
        if config['verbose']: print string.join(["%02x" % ord(x) for x in msg], ' ')
        return

    def sendDHCPRequest(self, req):
        if config['verbose']:
            print (1, req.htype, req.hlen, req.hops, req.xid, req.secs, 0,
                   req.ciaddr, req.yiaddr, req.siaddr, req.giaddr)
        data028 = struct.pack('!bbbblHHLLLL', 1, req.htype, req.hlen, req.hops, req.xid, req.secs, 0,
                              req.ciaddr, req.yiaddr, req.siaddr, req.giaddr)
        datachaddr = req.chaddr + struct.pack('8s', '')
        magic_cookie = struct.pack('BBBB', 99, 130, 83, 99)
        dhcp_request_option = struct.pack('bbb', 53, 1, DHCPREQUEST)
        client_identifier_option = struct.pack('BBB', OPTION_CLIENT_IDENTIFIER, 9, 1) + req.chaddr
        server_identifer_option = struct.pack('!BBL', OPTION_SERVER_IDENTIFIER , 4,
                                              req.siaddr)
        #ntp_option = struct.pack('bbl', 42, 4, 0)
        end_option = struct.pack('B', 0xff)
        padding = struct.pack('20s', '')
        full_request = (data028 + datachaddr + struct.pack('64s128s', '', '')
                        + magic_cookie
                        + dhcp_request_option
                        + client_identifier_option
                        + server_identifer_option
                        + parameter_request_list
                        + end_option
                        + padding)
        siaddr = struct.unpack('!BBBB', struct.pack('!L', req.siaddr))
        siaddrstr = '%d.%d.%d.%d' % (siaddr[0], siaddr[1], siaddr[2], siaddr[3])
        if config['verbose']: print 'Sending DHCPREQUEST'
        bootp_port.write(full_request, (siaddrstr, 67))
        if config['verbose']:
            print string.join(["%02x" % ord(x) for x in full_request], ' ')
            print 'dhcp request sent'
        return

    def datagramReceived(self, data, addr):
        (ipaddr, port) = addr
        if (port == 67 or port == 68):
            self.handleDHCPDatagram(data, addr)
        elif (port == 167 or port == 168):
            self.handleTDHCPDatagram(data, addr)
            
    def handleDHCPDatagram(self, data, addr):
        if config['verbose']: print addr
        (mtype, htype, hlen, hops, xid, secs, flags, ciaddr, yiaddr, siaddr, giaddr) = struct.unpack('!bbbblHHLLLL', data[0:28])
        flags = 0
        if config['verbose']: print (mtype, htype, hlen, hops, xid, secs, flags, ciaddr, yiaddr, siaddr, giaddr)
        chaddr= data[28:28+hlen]
        if client_requests.has_key(chaddr):
            if config['verbose'] > 1: print string.join(["%02x" % ord(x) for x in data], ' ')
            req = client_requests[chaddr]
            if req.siaddr == 0 or req.siaddr == siaddr:
                options = data[236:]
                req.parseOptions(options)
                req.yiaddr = yiaddr
                req.ciaddr = yiaddr
                req.siaddr = siaddr
                if req.options[OPTION_DHCP_MESSAGE_TYPE] == DHCPOFFER:
                    self.sendDHCPRequest(req)
                elif req.options[OPTION_DHCP_MESSAGE_TYPE] == DHCPACK:
                    self.sendTDHCPResponse(req)
                elif req.options[OPTION_DHCP_MESSAGE_TYPE] == DHCPDISCOVER:
                    ## we sent this out so ignore it  
                    pass
                else:
                    print ('unexpected DHCP Message type %d for chaddr %s'
                           % (req.options[OPTION_DHCP_MESSAGE_TYPE],
                              string.join(['%x' % ord(x) for x in chaddr], ':')))
            else:
                ## ignore extra server responses
                if config['verbose']: print 'response from other server'
                pass
            pass
        pass

    def handleTDHCPDatagram(self, data, addr):
        if config['verbose']: print 'tdhcp packet from ', addr
        (ipaddr, port) = addr
        ## pad to minimum size and resend
        (mtype, htype, hlen, hops, xid, secs, flags, ciaddr, yiaddr, siaddr, giaddr) = struct.unpack('!bbbblHHLLLL', data[0:28])
        giaddrbytes = inet_pton(AF_INET, config['ipaddr'])
        (giaddr,) = struct.unpack('!L', giaddrbytes)
        chaddr = data[28:28+hlen]
        req = DHCPRequest(mtype, htype, hlen, hops, xid, secs, flags, ciaddr, yiaddr, siaddr, giaddr, chaddr)
        
        (orig_ciaddr,) = struct.unpack('!L', inet_pton(AF_INET, ipaddr))
        
        req.orig_ciaddr = orig_ciaddr
        client_requests[chaddr] = req

        ## send dhcpdiscover
        if config['verbose']: print 'Sending DHCPDISCOVER'
        data = data[0:24] + giaddrbytes + data[28:]
        magic_cookie = struct.pack('BBBB', 99, 130, 83, 99)
        dhcp_request_option = struct.pack('bbb', 53, 1, DHCPDISCOVER)
        client_identifier_option = struct.pack('BBB', 0x3d, 9, 1) + chaddr
        end_option = struct.pack('B', 0xff)
        full_request = (data + struct.pack('64s128s', '', '')
                        + magic_cookie
                        + dhcp_request_option
                        + client_identifier_option
                        + parameter_request_list
                        + end_option)
        bootp_port.write(full_request, ('255.255.255.255', 67))

def usage(dict):
    print """
    Usage: tdhcpd-relay.py [OPTIONS]

    Valid options are:

         -v, --verbose        May be repeated for more detail
         -h, --help           This help
         -s, --bootps         Listen on port 67
         -c, --bootpc         Listen on port 68
         -i, --ipaddr         IP address of this host
         """ % dict
    sys.exit(0)


try:
    (options, argv) = getopt.getopt(sys.argv[1:], 'i:vhcs',
                                    ['ipaddr=', 'verbose', 'help', 'bootpc', 'bootps'])
except Exception, e:
    print e
    usage(config)

for (k,v) in options:
    if k in ('-v', '--verbose'):
        config['verbose'] += 1
    elif k in ('-h', '--help'):
        usage(config)
    elif k in ('-i', '--ipaddr'):
        config['ipaddr'] = v
    elif k in ('-s', '--bootps'):
        config['bootps'] = 1
    elif k in ('-c', '--bootps'):
        config['bootpc'] = 1

if not config['ipaddr']:
    print "ipaddr must be specified"
    usage(config)

if len(argv) > 1:
    print "too many arguments"
    usage(config)

server1 = DHCPServer()
server2 = DHCPServer()
server3 = DHCPServer()
if config['bootps']:
    bootps_port = reactor.listenUDP(67, server1)
    bootps_port.socket.setsockopt(SOL_SOCKET, SO_BROADCAST, 1)
    bootp_port = bootps_port
if config['bootpc']:
    bootpc_port = reactor.listenUDP(68, server2)
    bootpc_port.socket.setsockopt(SOL_SOCKET, SO_BROADCAST, 1)
    bootp_port = bootpc_port
    
tdhcp_port = reactor.listenUDP(167, server3)
reactor.run()
