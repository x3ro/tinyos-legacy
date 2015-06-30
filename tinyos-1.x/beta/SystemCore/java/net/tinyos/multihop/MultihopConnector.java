/** 
 *
 * Interface to the MultihopRSSI routing component
 *
 * @author Gilman Tolle <get@cs.berkeley.edu>
 * @since  0.1
 */

package net.tinyos.multihop;

import net.tinyos.message.*;
import net.tinyos.util.*;

import java.io.*; 
import java.text.*;
import java.util.*;

public class MultihopConnector implements MessageListener {

  public static int TOS_BCAST_ADDR = 0xffff;
  public static int DEFAULT_MOTE_ID = 0xfffe;
  private static int BCAST_ID = 0xff;

  private MoteIF moteIF;

  private int spAddr;

  private HashMap idTable = new HashMap();

  public MultihopConnector() {

    String moteid = Env.getenv("MOTEID");
    if (moteid == null) {
      this.spAddr = DEFAULT_MOTE_ID;
    } else {
      this.spAddr = Integer.parseInt(moteid);
    }
    
    try {
      moteIF = new MoteIF((Messenger)null);
      moteIF.registerListener(new MultihopLayerMsg(), this);
    } catch (Exception e) {
      System.out.println("ERROR: Couldn't contact serial forwarder.");
      System.exit(1);
    }

    TOSBaseCmdMsg cmdMsg = new TOSBaseCmdMsg();
    cmdMsg.set_addrChanged((byte)1);
    cmdMsg.set_addr(this.spAddr);
    cmdMsg.set_llAckChanged((byte)1);
    cmdMsg.set_llAck((short)1);

    /*
    System.err.println("Enabling TOSBase with link-layer ACKs");
    send(cmdMsg);
    */
  }

  public synchronized void send(Message m) {
    try {
      moteIF.send(MoteIF.TOS_BCAST_ADDR, m);
    } catch (IOException e) {
      e.printStackTrace();
      System.out.println("ERROR: Can't send message");
      System.exit(1);
    } catch (Exception e) {
      e.printStackTrace();
    }
  }

  public void registerListener(int id, MessageListener m) {

    HashSet listenerSet = (HashSet) idTable.get(new Integer(id));
    
    if (listenerSet == null) {
      listenerSet = new HashSet();
      idTable.put(new Integer(id), listenerSet);
    }
    listenerSet.add(m);
  }

  synchronized public void messageReceived(int to, Message m) {

    MultihopLayerMsg mhMsg = (MultihopLayerMsg)m;

    if (to != TOS_BCAST_ADDR && to != spAddr) 
      return;

    HashSet promiscuousSet = (HashSet) idTable.get(new Integer(BCAST_ID));
    HashSet listenerSet = (HashSet) idTable.get(new Integer(mhMsg.get_type()));
    
    if (listenerSet != null && promiscuousSet != null) {
      listenerSet.addAll(promiscuousSet);
    } else if (listenerSet == null && promiscuousSet != null) {
      listenerSet = promiscuousSet;
    }

    if (listenerSet == null) {
/*
      System.out.println("No Listener for type: " + mhMsg.get_type());
      System.out.println(mhMsg);
*/
      return;
    }

    for(Iterator it = listenerSet.iterator(); it.hasNext(); ) {
      MessageListener ml = (MessageListener) it.next();
      ml.messageReceived(to, mhMsg);
    }
  }

  public static void main(String args[]) {

    if (args.length < 1) {
      System.err.println("usage: java net.tinyos.multihop.MultihopConnector <SP id>");
      System.exit(1);
    }
    
    new MultihopConnector();
  }
}
