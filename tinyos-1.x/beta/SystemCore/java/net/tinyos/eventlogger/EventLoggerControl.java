package net.tinyos.eventlogger;

import java.io.*;
import net.tinyos.util.*;
import net.tinyos.message.*;
import net.tinyos.multihop.*;

public class EventLoggerControl implements MessageListener {

  private MoteIF moteIF;
  private MultihopConnector mhConnector;

  private EventLoggerSchema schema;

  public EventLoggerControl() {
    moteIF = new MoteIF((Messenger)null);
  }

  public EventLoggerControl(String filename) {

    moteIF = new MoteIF((Messenger)null);
    schema = new EventLoggerSchema(filename);
    mhConnector = new MultihopConnector();
    mhConnector.registerListener(LogEntryMsg.AM_TYPE, this);
  }

  public void play(int nodeID, int speed) {
    DripMsg dripMsg = new DripMsg(DripMsg.DEFAULT_MESSAGE_SIZE +
				  NamingMsg.DEFAULT_MESSAGE_SIZE +
				  EventLoggerCmdMsg.DEFAULT_MESSAGE_SIZE);

    dripMsg.set_metadata_id((short)EventLoggerCmdMsg.AM_TYPE);
    dripMsg.set_metadata_seqno((byte)0);

    NamingMsg namingMsg = new NamingMsg(dripMsg, dripMsg.offset_data(0),
					NamingMsg.DEFAULT_MESSAGE_SIZE +
					EventLoggerCmdMsg.DEFAULT_MESSAGE_SIZE);
    namingMsg.set_ttl((short)0xff);
    namingMsg.set_group((short)0xff);
    namingMsg.set_addr((short)nodeID);
    
    EventLoggerCmdMsg cmdMsg = new EventLoggerCmdMsg(namingMsg, 
						     namingMsg.offset_data(0),
						     EventLoggerCmdMsg.DEFAULT_MESSAGE_SIZE);

    cmdMsg.set_commandID((short)1);
    cmdMsg.set_playbackSpeed(speed);

    send(dripMsg);
  }

  public void stop(int nodeid) {
    sendCommand(nodeid, 2);
  }
  public void pause(int nodeid) {
    sendCommand(nodeid, 3);
  }
  public void rewind(int nodeid) {
    sendCommand(nodeid, 4);
  }
  public void current(int nodeid) {
    sendCommand(nodeid, 5);
  }

  private void sendCommand(int nodeID, int commandID) {

    DripMsg dripMsg = new DripMsg(DripMsg.DEFAULT_MESSAGE_SIZE + 
				  NamingMsg.DEFAULT_MESSAGE_SIZE +
				  EventLoggerCmdMsg.DEFAULT_MESSAGE_SIZE);

    dripMsg.set_metadata_id((short)EventLoggerCmdMsg.AM_TYPE); 
    dripMsg.set_metadata_seqno((byte)0);

    NamingMsg namingMsg = new NamingMsg(dripMsg, dripMsg.offset_data(0),
					NamingMsg.DEFAULT_MESSAGE_SIZE +
					EventLoggerCmdMsg.DEFAULT_MESSAGE_SIZE);
    namingMsg.set_ttl((short)0xff);
    namingMsg.set_group((short)0xff);
    namingMsg.set_addr((short)nodeID);
    
    EventLoggerCmdMsg cmdMsg = new EventLoggerCmdMsg(namingMsg, 
						     namingMsg.offset_data(0),
						     EventLoggerCmdMsg.DEFAULT_MESSAGE_SIZE);
    cmdMsg.set_commandID((short)commandID);

    send(dripMsg);
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

  public void messageReceived(int to, Message m) {
    
    MultihopLayerMsg mhMsg = (MultihopLayerMsg) m;
    LogEntryMsg logEntry = 
      new LogEntryMsg(mhMsg, mhMsg.offset_data(0), 
		      mhMsg.dataLength()
		      - mhMsg.offset_data(0));
    
    System.out.print(mhMsg.get_originaddr() + ": " + 
		     logEntry.get_entryID() + " " + 
//		     logEntry.get_entryKey() + "\t" + 
		     "@ " + logEntry.get_entryTimestamp() + " ");

    try {
      System.out.println(schema.convertMessage(logEntry, 
					       logEntry.get_entryKey()));
    } catch (Exception e) {
      System.out.println(e);
      e.printStackTrace();
      Dump.dump(System.out, "Bad Packet", logEntry.dataGet());
    }

  }

  public static void main(String args[]) {

    if (args.length < 2) {
      System.err.println("usage: java net.tinyos.eventlogger.EventLoggerControl <Schema file> <Node ID> <command>");
      System.err.println("commands: --play <report period>, --stop, --pause, --rewind, --current");
      System.exit(1);
    }

    String filename = args[0];
    EventLoggerControl elControl = new EventLoggerControl(filename);

    int nodeID = Integer.parseInt(args[1]);
    String command = args[2];

    if (command.equals("--play")) {
      int speed = Integer.parseInt(args[3]);
      elControl.play(nodeID, speed);
    } else if (command.equals("--stop")) {
      elControl.stop(nodeID);
      System.exit(0);
    } else if (command.equals("--pause")) {
      elControl.pause(nodeID);
      System.exit(0);
    } else if (command.equals("--rewind")) {
      elControl.rewind(nodeID);
      System.exit(0);
    } else if (command.equals("--current")) {
      elControl.current(nodeID);
      System.exit(0);
    }
  }
}
