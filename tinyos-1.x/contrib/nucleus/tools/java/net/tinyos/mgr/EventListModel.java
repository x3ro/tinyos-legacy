import java.util.*;
import javax.swing.*;
import net.tinyos.eventlogger.*;
 
public class EventListModel extends AbstractListModel implements Runnable, EventListener  {

  private List eventStringList = new ArrayList();
  
  private static int NODE_START_PERIOD = 4096;

  private EventConnector eventConnector;
  private EventLoggerControl eventControl;
  
  public EventListModel() {
    eventConnector = new EventConnector("event_schema.txt");
    eventConnector.setListener(this);
    
    eventControl = new EventLoggerControl();
    eventControl.stop(65535);
    
    Thread thread = new Thread(this);
    thread.setDaemon(true);
    thread.start();
  }

  public void run() {
    while (true) {
      System.out.println("Forcing log playback");
      eventControl.play(65535, 256);
      try {
	Thread.sleep(NODE_START_PERIOD);
      } catch (Exception e) {}
    }
  }

  synchronized public Object getElementAt(int index) {
    return eventStringList.get(eventStringList.size() - index - 1);
  }

  synchronized public int getSize() {
    return eventStringList.size();
  }

  synchronized public void eventReceived(LogEvent event) {
    String dateStr = event.receiveTime.toString();
    
    String eventString =     
      dateStr.substring(11, 19) + "  " +
      "Node: " + event.sourceAddr + " " +
      "Time: " + (event.nodeEventTime / 1000.0) + " sec " + 
      event.event;

    System.out.println(eventString);
    eventStringList.add(eventString);
    fireIntervalAdded(this, 0, 1);
  }
}
