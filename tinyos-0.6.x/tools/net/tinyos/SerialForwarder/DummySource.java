package net.tinyos.SerialForwarder;

/*
 * "Copyright (c) 2001 and The Regents of the University
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
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
 * $\Id$
 */


public class DummySource implements DataSource
{
    private byte[] m_dummyPacket = null;
    private int    m_nReadDelay  = 1000;

    public DummySource()
    {
        m_dummyPacket = new byte[SerialForward.PACKET_SIZE];
        m_dummyPacket[0] = (byte) 0x7E;

        for (int ii = 1; ii < m_dummyPacket.length - 2; ii++)
        {
                m_dummyPacket[ii] = (byte)ii;
        }

        int crc = calcrc ( m_dummyPacket, m_dummyPacket.length-2 );

        m_dummyPacket[m_dummyPacket.length - 2] = (byte) (crc & 0xFF);
        m_dummyPacket[m_dummyPacket.length - 1] = (byte) ((crc >> 8) & 0xFF);
    }

    public boolean OpenSource ( ) {
        SerialForward.VERBOSE( "Opening dummy data source");
        return true;
    }

    public boolean CloseSource  ( ) {
        SerialForward.VERBOSE( "Closing dummy data source");
        return true;
    }

    public byte[] ReadPacket ( )
    {
            SerialForward.nBytesRead += m_dummyPacket.length;

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