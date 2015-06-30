package net.tinyos.tools;

import java.io.*;
import net.tinyos.util.*;
import net.tinyos.message.*;

public class DripInject implements MessageListener {

  public static final short TOS_BCAST_ADDR = (short) 0xffff;
  
  private MoteIF mote;
  private long key;
  private int value;

  public DripInject() {
    mote = new MoteIF(PrintStreamMessenger.err);
    mote.registerListener(new DripMsg(), this);
  }

  public void inject(int component, int channel, int value) {

    DripMsg msg = new DripMsg();
    this.key = (component << 8) | (channel & (0xff)); 
    msg.set_metadata_key(key);
    this.value = value;

/*    
    if (useSeqno)
      msg.set_metadata_seqno((short)seqno);
    else
      msg.set_metadata_seqno((short)0);      
*/
    for(int i = 0; i < 4; i++) {
      msg.setElement_data(i, (short)((value & (0xff << 8*i)) >> 8*i));
    }
    System.out.println("Sending Probe Message...");
    System.out.println(msg);
    
    try {
      mote.send(TOS_BCAST_ADDR, msg);
    } catch (IOException e) {
      e.printStackTrace();
    }
  }

  public void messageReceived(int dest_addr, Message m) {
    DripMsg recMsg = (DripMsg) m;

    System.out.println("Received Network Message...");
    System.out.println(recMsg);
    
    if (recMsg.get_metadata_key() == key) {

      DripMsg msg = new DripMsg();
      msg.set_metadata_key(key);
      msg.set_metadata_seqno((short)(recMsg.get_metadata_seqno()+1));

      for(int i = 0; i < 4; i++) {
	msg.setElement_data(i, (short)((value & (0xff << 8*i)) >> 8*i));
      }

      try {

	System.out.println("Sending Update Message...");
	System.out.println(msg);
	mote.send(TOS_BCAST_ADDR, msg);

      } catch (IOException e) {
	e.printStackTrace();
      }
    } 
  }

  public static void usage() {
    System.err.println("Usage: java net.tinyos.tools.DripInject"+
		       " <component> <channel> <value> [seqno]");
  }

  public static void main(String[] argv) throws IOException {

    DripInject ij = new DripInject();

    if (argv.length < 3) {
      usage();
      System.exit(-1);
    }
    
    int component = Integer.parseInt(argv[0]);
    int channel = Integer.parseInt(argv[1]);
    int value = Integer.parseInt(argv[2]);
    int seqno;
    boolean useSeqno = false;

    if (argv.length == 4) {

      seqno = Integer.parseInt(argv[3]);
    }

    ij.inject(component, channel, value);
  }
}




