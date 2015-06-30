import java.util.*;

import net.tinyos.message.*;
import net.tinyos.util.*;

import net.tinyos.multihop.*;
import net.tinyos.drip.*;
import net.tinyos.eventlogger.*;

public class EventConnector implements MessageListener {
  
  private MoteIF moteIF;
  private MultihopConnector mhConnector;
  private EventLoggerSchema schema;
  private EventListener myListener;
  
  public EventConnector(String schemaFile) {
    schema = new EventLoggerSchema(schemaFile);
    try {
	moteIF = new MoteIF((Messenger)null);
	mhConnector = new MultihopConnector();
	mhConnector.registerListener(LogEntryMsg.AM_TYPE, this);
    } catch (Exception e) {
	System.out.println("ERROR: Couldn't contact serial forwarder.");
    }
  }

  public void setListener(EventListener el) {
    myListener = el;
  }

  public void messageReceived(int to, Message m) {

    LogEvent logEvent = new LogEvent();

    MultihopLayerMsg mhMsg = (MultihopLayerMsg) m;
    LogEntryMsg logEntry = 
      new LogEntryMsg(mhMsg, mhMsg.offset_data(0), 
		      mhMsg.dataLength()
		      - mhMsg.offset_data(0));

    logEvent.key = logEntry.get_entryKey();
    logEvent.seqno = logEntry.get_entryID();
    logEvent.sourceAddr = mhMsg.get_originaddr();
    logEvent.nodeEventTime = logEntry.get_entryTimestamp();
    logEvent.receiveTime = new Date();

    try {
      logEvent.event = schema.convertMessage(logEntry, 
					     logEntry.get_entryKey());
    } catch (Exception e) {
      System.out.println(e);
      e.printStackTrace();
      Dump.dump(System.out, "Bad Packet", logEntry.dataGet());
    }

    if (myListener != null)
      myListener.eventReceived(logEvent);
  }
}
