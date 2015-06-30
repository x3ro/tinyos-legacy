
import java.util.*;


/**
 * A <code>MotePacketParser</code> accumulates bytes until a complete mote
 * packet is received, then it sends the packet to its set of registered
 * <code>MotePacketListener</code>'s.
 *
 * @author Cory Sharp
 *   (<a href="mailto:cssharp@eecs.berkeley.edu">cssharp@eecs.berkeley.edu</a>)
 * @version $Revision: 1.2 $$Date: 2003/02/05 23:08:20 $
 */
public class MotePacketParser
{
  Vector m_packet_listeners;
  MotePacket m_packet;
  int m_offset;


  MotePacketParser()
  {
    m_packet_listeners = new Vector();
    m_packet = new MotePacket();
    m_offset = 0;
  }


  public void add_packet_listener( MotePacketListener ll )
  {
    if( !m_packet_listeners.contains( ll ) )
      m_packet_listeners.add( ll );
  }

  public void remove_packet_listener( MotePacketListener ll )
  {
    m_packet_listeners.remove( ll );
  }

  
  public void process_byte( int ii )
  {
    if( ii == 0x7e || m_offset != 0 )
    {
      m_packet.bytes[ m_offset++ ] = (byte)ii;

      if( m_offset == m_packet.bytes.length )
      {
	m_offset = 0;
	for( int nn=0; nn<m_packet_listeners.size(); nn++ )
	  ((MotePacketListener)m_packet_listeners.get( nn )).receive_packet( m_packet );
      }
    }
  }
}

