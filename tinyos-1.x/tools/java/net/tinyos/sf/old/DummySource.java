// $Id: DummySource.java,v 1.2 2003/10/07 21:46:03 idgay Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */


package net.tinyos.sf.old;

public class DummySource implements DataSource
{
    private byte[] m_dummyPacket = null;
    private int    m_nReadDelay  = 1000;
    private SerialForward sf;
    public DummySource(SerialForward SF)
    {
        sf=SF;
        m_dummyPacket = new byte[sf.PACKET_SIZE];
        m_dummyPacket[0] = (byte) 0x7E;

        for (int ii = 1; ii < m_dummyPacket.length - 2; ii++)
        {
                m_dummyPacket[ii] = (byte)ii;
        }

        int crc = calcrc ( m_dummyPacket, m_dummyPacket.length-2 );

        m_dummyPacket[m_dummyPacket.length - 2] = (byte) (crc & 0xFF);
        m_dummyPacket[m_dummyPacket.length - 1] = (byte) ((crc >> 8) & 0xFF);
    }
    public void setSerialForward(SerialForward SF) { sf = SF; }

    public boolean OpenSource ( ) {
        sf.VERBOSE( "Opening dummy data source");
        return true;
    }

    public boolean CloseSource  ( ) {
        sf.VERBOSE( "Closing dummy data source");
        return true;
    }

    public byte[] ReadPacket ( )
    {
            sf.nBytesRead += m_dummyPacket.length;

            try { Thread.currentThread ().sleep( m_nReadDelay ); }
            catch (Exception e ) { }

            return m_dummyPacket;
    }

    public boolean WritePacket ( byte[] packet ) { return true; }

    private static int calcrc(byte[] packet, int count)
    {
	int crc=0, index=0;
	int i;

	while (count > 0)
        {
	    crc = crc ^ (int) packet[index] << 8;
	    index++;
	    i = 8;
	    do
	    {
		if ((crc & 0x8000) == 0x8000)
		    crc = crc << 1 ^ 0x1021;
		else
		    crc = crc << 1;
            }
	    while(--i != 0);
	    count --;
	}
	return (crc);
    }
}
