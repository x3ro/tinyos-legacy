import net.tinyos.util.*;
import net.tinyos.message.*;

public class PrintFailed implements MessageListener {

  MoteIF mote;
  
  PrintFailed() {
    // OK, connect to the serial forwarder and start receiving data
    mote = new MoteIF(PrintStreamMessenger.err);
    mote.registerListener(new RosterMsg(), this);
    mote.registerListener(new ResultPkt(), this);
  }

  
  /**
   * This method is called to signal message reception. to is
   * the destination of message m.
   * @param to the destination of the message (Note: to is only valid
   *   when using TOSBase base stations)
   * @param m the received message
   */
  public void messageReceived(int to, Message m) {
    if (m instanceof RosterMsg) {
      RosterMsg rm = (RosterMsg)m;
      int i, j, moteID = 0, cnt = 0, byteLen;
      short curByte;

      System.out.print("Received message (round = " 
		       + rm.get_round() +
		       ", compressed = "
		       + rm.get_alive_compressed() +
		       ", superSkip = "
		       + rm.get_alive_superSkip() +
		       ", len = "
		       + rm.get_alive_len() + ") ");

      byteLen = rm.get_alive_len();

      for (i = 0; i < byteLen; i++) {
	curByte = rm.getElement_alive_data(i);

	for (j = 0; j < 8; j++) {
	  if ((curByte & (1 << j)) != 0) {

	    cnt++;

	    System.out.print(moteID + " ");
	  }

	  moteID++;
	}
      }

      System.out.println("\nCount = "+cnt);
      

    } else if (m instanceof ResultPkt) {
      ResultPkt rp = (ResultPkt)m;

      System.out.println("UPDATE: Failed: " 
			 + rp.get_numFailedNodes() +
			 "; bytes: "
			 + rp.get_bytesSent() + 
			 "; rounds: "
			 + rp.get_numRounds() +
			 "; par: " 
			 + rp.get_parentAddr() +
			 "; tree: "
			 + rp.get_treeLevel() +
			 "; late: " 
			 + rp.get_numLate() +
			 "; full: "
			 + rp.get_numFullUpd());
			 
    } else {
      throw new RuntimeException("messageReceived: Got bad message type: "
				 +m);
    }
    
  }

  static PrintFailed pf;

  public static void main(String[] args) {
    pf = new PrintFailed();
  }

}
