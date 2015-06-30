#!/usr/bin/python
#
# Copyright (c) 2005 Hewlett-Packard Company
# All rights reserved
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:

#    * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#    * Redistributions in binary form must reproduce the above
#       copyright notice, this list of conditions and the following
#       disclaimer in the documentation and/or other materials provided
#       with the distribution.
#    * Neither the name of the Hewlett-Packard Company nor the names of its
#       contributors may be used to endorse or promote products derived
#       from this software without specific prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#
#  ZigbeeDecoding module
#
#  Parse and display packets captured from TOSBase or ZSniff
#
#  Author:  Andrew Christian <andrew.christian@hp.com>
#           November, 2004

import struct,time

from twisted.internet import protocol

MULTI_FORMAT = "%-14s "

###########################################################################################

class MyError(Exception):
    def __init__(self,value):
        self.value = value
    def __str__(self,value):
        return repr(self.value)

###########################################################################################

def checksum(data):
    result = 0
    while len(data) > 1:
        value = struct.unpack("!H", data[:2])[0]
        result += value
        if result > 0xffff:
            result -= 0xffff

        data = data[2:]

    if len(data):
        value = ord(data[0])
        result += value
        if result > 0xffff:
            result -= 0xffff

    return result

###########################################################################################

class BasicMessageReceiver(protocol.Protocol):
    """A receiver for Basic Message strings

    A basic message is terminated by 0x7e.  All
    0x7e and 0x7d characters are replaced by 0x7d 0x20^byte
    """
    MAX_LENGTH = 256

    def __init__(self,verbose=0):
        self.recvd        = ""
        self.synchronized = False
        self.verbose      = verbose
        self.start_time   = time.time()

    def msgReceived(self,msg):
        'Override this'
        raise NotImplementedError
    
    def dataReceived(self,recvd):
        if self.verbose > 1: print 'received', ["%02x" % ord(x) for x in recvd]
        self.recvd = self.recvd + recvd
        while len(self.recvd):
            index = self.recvd.find(chr(0x7e))
            if index < 0:
                break

            msg = self.recvd[:index]
            self.recvd = self.recvd[index+1:]

            if not self.synchronized:
                if len(msg) and self.verbose:
                    print 'Synchronizing', len(msg), 'characters', ["%02x" % ord(x) for x in msg]
                self.synchronized = True
            elif len(msg):
                vlist = msg.split(chr(0x7d))
                if self.verbose > 2: print 'vlist', vlist
                try:
                    msg = vlist[0] + ''.join([chr(ord(v[0]) ^ 0x20) + v[1:] for v in vlist[1:]])
                    self.msgReceived(msg)
                except Exception, e:
                    # A bad packet can have two 'x7d' bytes in a row
                    if self.verbose:
                        print 'Decoding error', e, vlist

        if len(self.recvd) > BasicMessageReceiver.MAX_LENGTH:
            self.recvd = ''
            self.synchronized = False
            print 'Lost synchronization'

    def sendMessage(self,data):
        'Send an encoded string'
        if self.verbose: print 'Raw send:', ":".join(["%02x" % ord(x) for x in data])
        msg = chr(0x7e)
        escape_list = (chr(0x7d), chr(0x7e))
        for d in data:
            if d in escape_list:
                msg += chr(0x7d) + chr(ord(d) ^ 0x20)
            else:
                msg += d
        msg += chr(0x7e)
        if self.verbose > 1: print 'Writing', ":".join(["%02x" % ord(x) for x in msg])
        self.transport.write(msg)
            

###########################################################################################

def extract_address(mode,msg,intra_pan=''):
    'Extract 802.15.4 address'
    pan = ''
    addr = ''

    if mode:
        if intra_pan:
            pan = intra_pan
        else:
            if len(msg) < 2:
                raise MyError("Extract_Address: " + len(data))

            pan = "%02x:%02x" % (ord(msg[1]), ord(msg[0]))
            msg = msg[2:]

        if mode == 2:
            if len(msg) < 2:
                raise MyError("Extract_Address(2): " + len(data))

            addr = "%02x:%02x" % (ord(msg[1]), ord(msg[0]))
            msg = msg[2:]

        elif mode == 3:
            if len(msg) < 8:
                raise MyError("Extract_Address(2): " + len(data))

            addr = ':'.join(["%02x" % ord(x) for x in msg[:8]])
            msg = msg[8:]

    return (pan,addr,msg)

###########################################################################################

class Packet:
    'A Generic packet of data'
    def __init__(self, data, container=None):
        self.container_list = []
        self.data = data
        if container:
            self.decode( container )

    def isa(self,t):
        'Determine if we are a particular type'
        for c in self.container_list:
            if c.TYPE == t:
                return True

        return False

    def decode(self, container):
        'Recursively descend and create containment objects'
        data = self.data

        while container:
            c = container(self)
            self.container_list.append(c)
            data = c.decode(data)
            container = c.child()
            
        self.data = data

    def singleline(self, max_data=10000):
        'Return a representation of ourselves on a single line of text'
        r = ''
        if self.data:
            r = ':'.join(["%02x" % ord(x) for x in self.data[:max_data]])
            if max_data >= 0 and max_data < len(self.data):
                r += "..."

        for c in self.container_list:
            h = c.header()
            if len(h) > 0:
                if len(r):  r = h + " " + r
                else:       r = h
            f = c.footer()
            if len(f) > 0:
                if len(r):  r = r + " " + f
                else:       r = f

        return r

    def multiline(self):
        'Return a list of strings representing ourselves on multiple lines'
        rlist = []
        for c in self.container_list:
            r = c.multi()
            if r: rlist.append(r)

        if self.data:
            r = ':'.join(["%02x" % ord(x) for x in self.data])
            rlist.append(r)

        return rlist
                
    def contains(self,container):
        'Do we contain this type of object?'
        for c in self.container_list:
            if isinstance(c,container):
                return True
        return False
    
    def __str__(self):
        return self.singleline()
    
###########################################################################################

class Container:
    'A generic container class.  Not meant to be instantiated as an object'
    TYPE = 'generic'
    
    def __init__(self,pkt):
        self._pkt = pkt
        
    def decode(self,data):
        return data
    
    def child(self):
        return None

    def header(self):
        return ''

    def footer(self):
        return ''

    def multi(self):
        'Data to return on a multi-line packet'
        return self.header()

###########################################################################################

bcn_protocols = ('Zigbee', 'HandheldsIP')

class BeaconFrame(Container):
    TYPE = 'beacon'
    
    def decode(self,data):
        if len(data) < 3:
            raise MyError("BeaconFrame too short: " + len(data))

        pkt = self._pkt

        pkt.bcn_superframe, pkt.bcn_gts_spec = struct.unpack('HB', data[:3])
        data = data[3:]

        pkt.bcn_beacon_order      = pkt.bcn_superframe & 0x000f
        pkt.bcn_superframe_order  = (pkt.bcn_superframe & 0x00f0) >> 4
        pkt.bcn_final_cap_slot    = (pkt.bcn_superframe & 0x0f00) >> 8
        pkt.bcn_battery_life_ext  = ((pkt.bcn_superframe & 0x1000) != 0)
        pkt.bcn_pan_coordinator   = ((pkt.bcn_superframe & 0x4000) != 0)
        pkt.bcn_assoc_permit      = ((pkt.bcn_superframe & 0x8000) != 0)

        pkt.bcn_gts_desc_count    = pkt.bcn_gts_spec & 0x07
        pkt.bcn_gts_permit        = ((pkt.bcn_gts_spec & 0x80) != 0)

        if pkt.bcn_gts_desc_count > 0:
            if len(data) < 1:
                raise MyError("BeaconFrame(2) too short: " + len(data))

            pkt.bcn_gts_directions = ord(data[0]) & 0x7f
            data = data[1:]
            pkt.bcn_gts_list = []
            for i in range(pkt.bcn_gts_desc_count):
                if len(data) < 3:
                    raise MyError("BeaconFrame(3) too short: " + len(data))

                addr   = ':'.join(["%02x" % ord(x) for x in data[:2]])
                slot   = ord(data[2]) & 0x0f
                length = ord(data[2]) & 0xf0
                pkt.bcn_gts_list.append((addr,slot,length))
                data = data[3:]

        if len(data) < 1:
            raise MyError("BeaconFrame(4) too short: " + len(data))

        pkt.bcn_pending_short_count = ord(data[0]) & 0x07
        pkt.bcn_pending_long_count  = ord(data[0]) & 0x70
        data = data[1:]
        pkt.bcn_pending_short_list = []
        pkt.bcn_pending_long_list  = []

        for i in range(pkt.bcn_pending_short_count):
            if len(data) < 2:
                raise MyError("BeaconFrame(5) too short: " + len(data))

            addr = ':'.join(["%02x" % ord(x) for x in data[:2]])
            data = data[2:]
            pkt.bcn_pending_short_list.append(addr)

        for i in range(pkt.bcn_pending_long_count):
            if len(data) < 6:
                raise MyError("BeaconFrame(6) too short: " + len(data))

            addr = ':'.join(["%02x" % ord(x) for x in data[:6]])
            data = data[6:]
            pkt.bcn_pending_long_list.append(addr)

        pkt.bcn_protocol_id      = -1
        pkt.bcn_protocol_id_name = 'Undefined'
        if len(data):
            pkt.bcn_protocol_id = ord(data[0])
            if pkt.bcn_protocol_id < len(bcn_protocols):
                pkt.bcn_protocol_id_name = bcn_protocols[pkt.bcn_protocol_id]
            else:
                pkt.bcn_protocol_id_name = 'Unknown (%d)' % pkt.bcn_protocol_id
            data = data[1:]
            
        return data

    def line_format(self):
        pkt = self._pkt
        r = "beacon_order=%(bcn_beacon_order)d superframe_order=%(bcn_superframe_order)d final_cap_slot=%(bcn_final_cap_slot)d" % vars(pkt)
        if pkt.bcn_battery_life_ext: r += ' BATLIFE'
        if pkt.bcn_pan_coordinator:  r += ' PANCOORD'
        if pkt.bcn_assoc_permit:     r += ' ASSOC_OK'
        if pkt.bcn_gts_desc_count > 0:
            r += " gts_count=%d" % pkt.bcn_gts_desc_count + pkt.bcn_gts_list
        if pkt.bcn_pending_short_count > 0:
            r += " pending_short=%d" % pkt.bcn_pending_short_count + pkt.bcn_pending_short_list
        if pkt.bcn_pending_long_count > 0:
            r += " pending_long=%d" % pkt.bcn_pending_long_count + pkt.bcn_pending_long_list
        r += " protocol=" + pkt.bcn_protocol_id_name
        return r
        
    def header(self):
        return "BEACON " + self.line_format()

    def multi(self):
        return MULTI_FORMAT % "Beacon" + self.line_format()

###########################################################################################

cmd_names =('ASSOC_REQUEST', 'ASSOC_RESPONSE', 'DISASSOC_NOTIFY', 'DATA_REQUEST',
            'PAN_ID_CONFLICT', 'ORPHAN_NOTIFY', 'BEACON_REQUEST', 'COORDINATOR_REALIGN',
            'GTS_REQUEST' )

class CommandFrame(Container):
    TYPE = 'cmd'
    
    def decode(self,data):
        if len(data) < 1:
            raise MyError("CommandFrame too short: " + len(data))

        pkt = self._pkt
        pkt.cmd_num = ord(data[0])
        if pkt.cmd_num > 0 and pkt.cmd_num <= 9:
            pkt.cmd_name = cmd_names[pkt.cmd_num - 1]
        else:
            pkt.cmd_name = "UNKNOWN(%d)" % pkt.cmd_num

        return data[1:]

    def header(self):
        pkt = self._pkt
        return pkt.cmd_name

    def multi(self):
        return MULTI_FORMAT % "Command" + self.header()

###########################################################################################

class ARPPacket(Container):
    'Request or respond to ARP'

    TYPE = 'arp'
    
    def decode(self,data):
        if len(data) < 1:
            raise MyError("ARPPacket too short: " + len(data))

        pkt = self._pkt
        pkt.arp_type = ord(data[0])
        data = data[1:]
        if pkt.arp_type == 1:
            pkt.arp_name = 'REQUEST'
        elif pkt.arp_type == 2:
            pkt.arp_name = 'RESPONSE'
            if len(data) < 1:
                raise MyError("ARPPacket(2) too short: " + len(data))

            length = ord(data[0])
            data = data[1:]

            if len(data) < length:
                raise MyError("ARPPacket(3) too short: " + len(data))

            pkt.arp_mac = data[:length]
            data = data[length:]

            if len(data) < 4:
                raise MyError("ARPPacket(4) too short: " + len(data))

            pkt.arp_ip  = data[:4]
            data = data[4:]
        else:
            pkt.arp_name = 'UNKNOWN (%d)' % pkt.arp_type
        return data

    def line_format(self):
        pkt = self._pkt
        if pkt.arp_type == 2:
            mac = ":".join(["%02x" % ord(x) for x in pkt.arp_mac])
            ip  = ".".join(["%d" % ord(x) for x in pkt.arp_ip])
            return "%s %s %s" % (pkt.arp_name, mac, ip)
        
        return pkt.arp_name

    def header(self):
        return "ARP " + self.line_format()

    def multi(self):
        return MULTI_FORMAT % "ARP" + self.header()

###########################################################################################

class ICMPPacket(Container):
    'An ICMP frame'
    TYPE = 'icmp'
    
    def decode(self,data):
        pkt = self._pkt

        if len(data) < 4:
            raise MyError("ICMP data too short: " + len(data))

        pkt.icmp_type, pkt.icmp_code, pkt.icmp_checksum = struct.unpack('!BBH', data[:4])
        pkt.icmp_checksum_okay = (checksum(data) == 0xffff)
        return data[4:]
        
    def line_format(self):
        pkt = self._pkt
        p = "%(icmp_type)d %(icmp_code)d 0x%(icmp_checksum)04x" % vars(pkt)
        if pkt.icmp_type == 8 and pkt.icmp_code == 0:
            p = "PING REQUEST " + p
        elif pkt.icmp_type == 0 and pkt.icmp_code == 0:
            p = "PING REPLY " + p

        if pkt.icmp_checksum_okay:
            p += " (okay)"
        else:
            p += " (not okay)"
        return p

    def header(self):
        return "ICMP " + self.line_format()

    def multi(self):
        return MULTI_FORMAT % "ICMP" + self.line_format()


###########################################################################################

#IP_PROTOCOLS = { 1 : ICMPPacket,
#                 6 : TCPPacket,
#                 17: UDPPacket }

class IPPacket(Container):
    'An encapsulated IP frame'
    TYPE = 'ip'
    
    def decode(self,data):
        if len(data) < 20:
            raise MyError("IP Data too short: " + len(data))

        pkt = self._pkt

        (vl, pkt.ip_tos, pkt.ip_total_length, pkt.ip_id,
         frags, pkt.ip_ttl, pkt.ip_protocol, pkt.ip_checksum) = struct.unpack('!BBHHHBBH', data[:12])

        pkt.ip_version    = (vl & 0xf0) >> 4
        pkt.ip_header_len = (vl & 0x0f) * 4
        pkt.ip_frag_reserved = ((frags & 0x8000) != 0)
        pkt.ip_frag_dont     = ((frags & 0x4000) != 0)
        pkt.ip_frag_more     = ((frags & 0x2000) != 0)
        pkt.ip_fragment_offset = frags & 0x1fff
        pkt.ip_source = ".".join(["%d" % ord(x) for x in data[12:16]])
        pkt.ip_dest   = ".".join(["%d" % ord(x) for x in data[16:20]])

        if len(data) < pkt.ip_header_len:
            raise MyError("IP data too short (%d) for IP Header length (%d)" % (len(data), pkt.ip_header_len)) 

        pkt.ip_extra = data[20:pkt.ip_header_len]
        pkt.ip_checksum_okay = (checksum(data[:pkt.ip_header_len]) == 0xffff)
        return data[pkt.ip_header_len:]

    def child(self):
        pkt = self._pkt
        if pkt.ip_protocol == 1:
            return ICMPPacket
        return None
    
    def line_format(self):
        pkt = self._pkt
        r = "%(ip_source)s > %(ip_dest)s version=%(ip_version)d chk=0x%(ip_checksum)04x" % vars(pkt)
        if pkt.ip_checksum_okay:
            r += " (okay)"
        else:
            r += " (not okay)"
        return r
        
    def header(self):
        return "IP " + self.line_format()

    def multi(self):
        return MULTI_FORMAT % "IP" + self.line_format()

###########################################################################################

class LinkLayer(Container):
    'A protocol byte at the front of a data frame'
    TYPE = 'll'
    
    def decode(self,data):
        if len(data) < 1:
            raise MyError("LinkLayer packet too short: " + len(data))
            
        pkt = self._pkt
        pkt.ll_protocol = ord(data[0])
        if pkt.ll_protocol == 1:
            pkt.ll_protocol_name = 'ARP'
        elif pkt.ll_protocol == 8:
            pkt.ll_protocol_name = 'IP'
        else:
            pkt.ll_protocol_name = 'UNKNOWN'
        return data[1:]

    def child(self):
        pkt = self._pkt
        if pkt.ll_protocol == 1:
            return ARPPacket
        if pkt.ll_protocol == 8:
            return IPPacket
        return None

    def header(self):
        pkt = self._pkt
        return "LL(%s)" % pkt.ll_protocol_name

    def multi(self):
        return MULTI_FORMAT % "Link Layer" + self.header()


###########################################################################################

class DataFrame(Container):
    'A standard 802.15.4 data frame.  We usually stop decoding here'
    TYPE = 'data'
    
    def header(self):
        return 'DATA'

    def multi(self):
        return ''

###########################################################################################

class AckFrame(Container):
    TYPE = 'ack'
    
    def header(self):
        return 'ACK'

    def multi(self):
        return ''

###########################################################################################

class OtherFrame(Container):
    TYPE = 'other'
    
    def header(self):
        return 'OTHER=%d' % self._pkt.mac_frame_type

###########################################################################################

class IEEE_802_15_4_Packet(Container):
    'Extract the first set of bytes from the packet in 802.15.4 format'
    TYPE = 'mac'
    
    def decode(self,data):
        if len(data) < 3:
            raise MyError("IEEE802.15.4 packet too short: " + len(data))
            
        pkt = self._pkt
        pkt.mac_fcf, pkt.mac_dsn = struct.unpack('HB', data[:3])

        pkt.mac_frame_type     = pkt.mac_fcf & 0x0007
        pkt.mac_security_p     = pkt.mac_fcf & 0x0008
        pkt.mac_frame_pend     = pkt.mac_fcf & 0x0010
        pkt.mac_ack_request    = pkt.mac_fcf & 0x0020
        pkt.mac_intra_pan      = pkt.mac_fcf & 0x0040
        pkt.mac_dest_addr_mode = (pkt.mac_fcf & 0x0c00) >> 10
        pkt.mac_src_addr_mode  = (pkt.mac_fcf & 0xc000) >> 14

        fcf_text = ('BEACON', 'DATA', 'ACK', 'COMMAND', 'Res1', 'Res2', 'Res3', 'Res4')[pkt.mac_frame_type]
        if pkt.mac_security_p: fcf_text += ' SECURE'
        if pkt.mac_frame_pend: fcf_text += ' FRAMEPEND'
        if pkt.mac_ack_request: fcf_text += ' ACKREQUEST'
        if pkt.mac_intra_pan:   fcf_text += ' INTRAPAN'
        pkt.mac_fcf_text = fcf_text

        data = data[3:]
        (pkt.mac_dest_pan, pkt.mac_dest_addr, data) = extract_address(pkt.mac_dest_addr_mode, data)
        (pkt.mac_src_pan, pkt.mac_src_addr, data)   = extract_address(pkt.mac_src_addr_mode, data,
                                                              pkt.mac_intra_pan and pkt.mac_dest_pan )

        return data

    def child(self):
        pkt = self._pkt
        return (BeaconFrame, DataFrame, AckFrame, CommandFrame,
                OtherFrame, OtherFrame, OtherFrame, OtherFrame)[pkt.mac_frame_type]

    def header(self):
        pkt = self._pkt
        r = "fcf=%(mac_fcf)04x [%(mac_fcf_text)s] dsn=%(mac_dsn)3d" % vars(pkt)
        if pkt.mac_dest_pan: r += " dest=%(mac_dest_pan)s/%(mac_dest_addr)s" % vars(pkt)
        if pkt.mac_src_pan:  r += " src=%(mac_src_pan)s/%(mac_src_addr)s" % vars(pkt)
        return r

    def multi(self):
        return MULTI_FORMAT % "IEEE 802.15.4" + self.header()

###########################################################################################

class ChipconRadioPacket(Container):
    'The last two bytes are Chipcon RSSI and LQI information'
    TYPE = 'radio'
    
    def decode(self,data):
        if len(data) < 2:
            raise MyError("ChipconRadioPacket too short: " + len(data))
            
        pkt = self._pkt
        pkt.radio_rssi, pkt.radio_lqi = struct.unpack('bB',data[-2:])
        pkt.radio_crc_ok = ((pkt.radio_lqi & 0x80) != 0)
        pkt.radio_lqi &= 0x7f
        return data[:-2]

    def child(self):
        pkt = self._pkt
        if pkt.radio_crc_ok:
            return IEEE_802_15_4_Packet
        return None

    def footer(self):
        pkt = self._pkt
        return "rssi=%(radio_rssi)d lqi=%(radio_lqi)d crc=%(radio_crc_ok)s" % vars(pkt)

    def multi(self):
        return MULTI_FORMAT % "Chipcon" + self.footer()

###########################################################################################

class ChipconStatsPacket(Container):
    '''A response from the ZSniffer containing radio statistics
       We use a vlist to keep our keys in the order that I prefer
       '''
    TYPE = 'stats'
    
    vlist = ('rx_total', 'rx_bad_crc', 'rx_buf_full', 'rx_read_fail',
             'rx_fifo_fail', 'rx_fifo_fail2', 'rx_int_fixup',
             'tx_total', 'tx_dropped',
             'info', 'other1', 'other2', 'tx_last_delay')

    def decode(self,data):
        pkt = self._pkt
        if len(data) < 42:
            raise MyError("ChipconStatsPacket data too short: " + len(data))
        
        for (k,v) in zip(ChipconStatsPacket.vlist,struct.unpack('<9LBBHH',data)):
            setattr(pkt,k,v)
        return ''

    def header(self):
        pkt = self._pkt
        return 'RF_STAT: ' + ', '.join(['%s=%d' % (k,getattr(pkt,k)) for k in ChipconStatsPacket.vlist])

class RFChannelPacket(Container):
    'The radio channel'
    TYPE = 'channel'
    def decode(self,data):
        pkt = self._pkt
        if len(data) < 2:
            raise MyError("RFChannelPacket data too short: " + len(data))
        
        pkt.frequency = struct.unpack('>H', data[:2])[0]
        pkt.channel   = (pkt.frequency - 2048 - 357) / 5 + 11
        return data[2:]

    def header(self):
        pkt = self._pkt
        return 'RF_CHANNEL %d (freq %d)' % (pkt.channel, pkt.frequency)

class RFRadioState(Container):
    'The state of various radio pins'
    TYPE = 'state'
    def decode(self,data):
        pkt = self._pkt
        if len(data) < 2:
            raise MyError("RFChannelPacket data too short: " + len(data))
        
        pkt.state = struct.unpack('<H', data[:2])
        return data[2:]

    def header(self):
        pkt = self._pkt
        return 'RF_STATE %04x' % pkt.state


###########################################################################################

class UnknownPacket(Container):
    'An unknown command response'
    TYPE = 'unknown'
    def header(self):
        pkt = self._pkt
        return 'UNKNOWN'

###########################################################################################

g_ResponsePacketList = ( ChipconStatsPacket, RFChannelPacket, RFRadioState )

def decode_packet(msg,parse_data=False):
    if len(msg) > 1 and ord(msg[0]) == 1:
        r = ord(msg[1])
        if r >= 0 and r < len(g_ResponsePacketList):
            return Packet(msg[2:], g_ResponsePacketList[r])

    if len(msg) > 0 and ord(msg[0]) == 2:
        p = Packet(msg[1:], ChipconRadioPacket)
        if parse_data and p.contains( DataFrame ) and len(p.data):
            p.decode( LinkLayer )
        return p

    return Packet(msg, UnknownPacket)


