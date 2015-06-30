
/**
 * A <code>MotePacket</code> stores the bytes of a mote data packet.  Someday
 * maybe also perform some set of functions on those bytes.
 *
 * @author Cory Sharp
 *   (<a href="mailto:cssharp@eecs.berkeley.edu">cssharp@eecs.berkeley.edu</a>)
 * @version $Revision: 1.2 $$Date: 2003/02/05 23:07:42 $
 */
public class MotePacket
{
  /**
   * The actual bytes of the mote data packet
   */
  public byte bytes[];


  /**
   * Create a new mote packet with 36 uninitialized bytes.
   */
  public MotePacket()
  {
    bytes = new byte[36];
  }
}

