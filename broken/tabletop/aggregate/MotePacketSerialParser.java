
import java.util.*;
import java.io.*;
import javax.comm.*;


/**
 * A <code>MotePacketSerialParser</code> extends <code>MotePacketParser</code>
 * to open a serial port, receive mote bytes from that port, and process bytes
 * until EOF.
 *
 * @author <a href="http://www.cs.berkeley.edu/~mikechen/">Mike Chen</A>
 *     (<a href="mailto:mikechen@cs.berkeley.edu">mikechen@cs.berkeley.edu</A>)
 * @author Cory Sharp
 *   (<a href="mailto:cssharp@eecs.berkeley.edu">cssharp@eecs.berkeley.edu</a>)
 * @version $Revision: 1.2 $$Date: 2003/02/05 23:08:34 $
 */
public class MotePacketSerialParser extends MotePacketParser
{
  CommPortIdentifier portId;
  SerialPort port;
  String portName;
  InputStream in;
  OutputStream out;


  /**
   * Construct with the given serial port name.
   * @param portName serial port name
   */
  public MotePacketSerialParser( String portName )
  {
    this.portName = portName;
  }


  /**
   * Open the serial port.
   */
  public void open()
    throws NoSuchPortException
	 , PortInUseException
	 , IOException
	 , UnsupportedCommOperationException
  {
    portId = CommPortIdentifier.getPortIdentifier( portName );
    port = (SerialPort)portId.open( "MotePacketSerialParser", 0 );
    in = port.getInputStream();
    out = port.getOutputStream();

    port.setFlowControlMode( SerialPort.FLOWCONTROL_NONE );
    port.disableReceiveFraming();
    printPortStatus();
    port.setSerialPortParams(
	19200,
	SerialPort.DATABITS_8,
	SerialPort.STOPBITS_1,
	SerialPort.PARITY_NONE
      );

    printPortStatus();
  }


  /**
   * Display the port status: baud rate, data bits, stop bits, parity.
   */
  void printPortStatus()
  {
    System.out.println( "baud rate: " + port.getBaudRate() );
    System.out.println( "data bits: " + port.getDataBits() );
    System.out.println( "stop bits: " + port.getStopBits() );
    System.out.println( "parity:    " + port.getParity() );
  }


  /**
   * Print an enumeration of all of the comm ports on the machine.
   */
  public void printAllPorts()
  {
    Enumeration ports = CommPortIdentifier.getPortIdentifiers();
    
    if (ports == null)
    {
      System.out.println("No comm ports found!");
      return;
    }
    
    // print out all ports
    System.out.println("printing all ports...");
    while (ports.hasMoreElements()) {
      System.out.println("-  " + ((CommPortIdentifier)ports.nextElement()).getName());
    }
    System.out.println("done.");
  }

  
  /**
   * Process bytes from the serial port until EOF.
   */
  public void process_until_eof() throws IOException
  {
    int ii; 
    while( (ii = in.read()) != -1 )
      process_byte( ii );
  }
}


