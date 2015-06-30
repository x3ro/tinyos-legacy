
/**
 * A <code>LatchData</code> records both a value and the local time it
 * was assigned.  If no value is recored after a configured timeout duration,
 * then the immediately next value assignment is ignored and the timeout is
 * reset.  The intent is to ignore spurious, infrequent assignments.
 *
 * @author Cory Sharp
 *   (<a href="mailto:cssharp@eecs.berkeley.edu">cssharp@eecs.berkeley.edu</a>)
 * @version $Revision: 1.2 $$Date: 2003/02/05 23:07:11 $
 */
public class LatchData
{
  double m_value;
  double m_value_time;
  double m_latch_time;
  double m_latch_timeout;


  /**
   * Create a new instance with a <code>latch_timeout</code> of 20 seconds.
   */
  public LatchData() { clear(); m_latch_timeout = 20; }


  /**
   * Create a new instance with the specified <code>latch_timeout</code>.
   * @param latch_timeout in seconds
   */
  public LatchData( double latch_timeout )
  {
    clear();
    m_latch_timeout = latch_timeout;
  }


  /**
   * Get the current time in seconds.
   * @return local system time in seconds
   */
  public static double get_current_time()
  {
    return System.currentTimeMillis() / 1000.0;
  }


  /**
   * Determine if the next value assignment latches or assigns.
   * @param current_time in seconds
   * @return <code>true</code> if the next value assignment actually assigns;
   * <code>false</code> if the next value assignment only latches
   */
  public boolean is_latched( double current_time )
  {
    return (current_time - m_latch_time) < m_latch_timeout;
  }


  /**
   * Set the latch timeout period.
   * @param latch_timeout in seconds
   */
  public void set_latch_timeout( double latch_timeout )
  {
    m_latch_timeout = latch_timeout;
  }


  /**
   * Set the value or just latch.  The assignment actually only occurs if
   * <code>is_latched</code> is <code>true</code> for the current system time.
   * @param val the value to assign
   */
  public void set_value( double val )
  {
    double current_time = get_current_time();

    // yes, ignore the first reading if we haven't latched
    // ... for stupid simple spurious reading rejection

    if( is_latched( current_time ) )
    {
      m_value = val;
      m_value_time = current_time;
    }

    m_latch_time = current_time;
  }


  /**
   * Clears the recorded latch time, value time, and value.
   */
  public void clear()
  {
    m_value = 0;
    m_value_time = 0;
    m_latch_time = 0;
  }


  /**
   * Get the value that was last assigned during a latched state.
   * @return current value
   */
  public double get_value()
  {
    return m_value;
  }


  /**
   * Get the assignment time of the value that was last assigned during a
   * latched state.
   * @return value assignment time in seconds
   */
  public double get_value_time()
  {
    return m_value_time;
  }
}

