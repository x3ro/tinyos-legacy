import java.util.*;

public class LogEvent {
  public int key;
  public int sourceAddr;
  public int seqno;
  public long nodeEventTime;
  public Date receiveTime;
  public String event;

  public String toString() {
    return key + " " + sourceAddr + " " + seqno + " " + receiveTime + " " + nodeEventTime + " " + event;
  }
}
