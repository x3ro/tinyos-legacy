
/**
 * A <code>MotePacketListener</code> is notified when a complete mote packet is
 * received.
 *
 * @author Cory Sharp
 *   (<a href="mailto:cssharp@eecs.berkeley.edu">cssharp@eecs.berkeley.edu</a>)
 * @version $Revision: 1.2 $$Date: 2003/02/05 23:08:06 $
 */
public interface MotePacketListener
{
  /**
   * A complete mote packet has been received.
   * @param packet the actual packet data
   */
  public void receive_packet( MotePacket packet );
}

