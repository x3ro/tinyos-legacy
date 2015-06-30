/*
 * Copyright (C) 2003-2005 the University of Southern California.
 * All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or (at
 * your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public
 * License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA.
 *
 * In addition to releasing this program under the LGPL, the authors are
 * willing to dual-license it under other terms. You may contact the authors
 * of this project by writing to Wei Ye, USC/ISI, 4676 Admirality Way, Suite 
 * 1001, Marina del Rey, CA 90292, USA.
 */
/* Authors: Wei Ye
 *
 * listens all packets and pass them to UART.
 * Support different packet length. The first byte must be packet length.
 * Data is received from radio and passed to UART on a per byte basis.
 * If on a per packet basis, a short packet following a long packet may get
 * lost because the UART can't finish sending the long packet when the short
 * packet arrives.
 * The contents of each packet can be displayed by snoope.c at tools/.
 *
 */

includes config;

configuration Snooper { }

implementation
{
   components Main, SnooperM, PhyRadio, UART;
   
   Main.StdControl -> SnooperM;
   SnooperM.PhyControl -> PhyRadio;
   SnooperM.PhyNotify -> PhyRadio;
   SnooperM.PhyStreamByte -> PhyRadio;
   SnooperM.PhyPkt -> PhyRadio;
   SnooperM.UARTControl -> UART;
   SnooperM.UARTComm -> UART;
}




