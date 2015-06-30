/*
 * "Copyright (c) 2001 and The Regents of the University
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * $\Id$
 */

/**
 * File: SerialForward.java
 *
 * Description:
 * The SerialForward class provides many static functions
 * that handle the initialization of the serialforwarder
 * and/or the associated gui.
 *
 * @author <a href="mailto:bwhull@sourceforge.net">Bret Hull</a>
 */
package net.tinyos.sf;

import java.io.*;
import javax.swing.*;
import java.awt.event.*;

public class SerialForward {

  // appication defaults
  public ControlWindow cntrlWndw         = null;
  public DataSource    dataSource        = null;
  public static boolean       verboseMode       = true;
  public static boolean       debugMode         = false;
  public boolean       useDummyData      = false;
  public boolean       bSourceSim        = false;
  public boolean       bNidoSerialData   = false;
  public boolean       bLogDB            = false;
  public boolean       bSourceDB         = false;

  public static final int     SIM_LISTENPORT  = 10582;
  public static final String  SIM_ADDRESS     = "127.0.0.1";
  public static final int     SIM_WRITEPORT    = 10579;
  public int           serverPort        = 9000;
  public String        commPort          = "COM1";
  public boolean	      commPort_is_socket = false;
  public String	      commHost = null;
  public String	      commTCPPort = null;

  public int           BAUD_RATE         = 19200;
  public int           PACKET_SIZE       = 36;
  public byte[]        PACKET_DUMMY_DATA = new byte[PACKET_SIZE];

  private boolean      guiMode           = true;
  private boolean      displayHelp       = false;
  public int           nBytesRead        = 0;
  private int          nClients          = 0;
  private int          nPacketsRead      = 0;
  private int          nPacketsWritten   = 0;
  private ListenServer listener = null;

    public String strDBPassword = "";
    public String strDBUser = "";
    public boolean bPostgresql = false;
    public SerialPortIO serialPortIO=null;

    public static void main(String[] args) throws IOException {
          new SerialForward(args);
    }

    public SerialForward(String[] args) throws IOException {

        ProcessCommandLineArgs ( args );

    if ( displayHelp )
    {
      PrintHelp ();
    }
    else if ( guiMode )
    {
      CreateGui();
    }
    else {
      // no gui, user command line
      RunListenServer();
    }
  }

    /** Start a serial forwarded with the specified packet size & gui parameters */
      public static SerialForward run(boolean gui, String portName, int packet_size) throws IOException{
        return run(gui,portName,packet_size,false,true);
      }

       /** Start a serial forwarder with the option of running in "simulator" mode, which means
     read from the nido serial port*/
   public static SerialForward run(boolean gui, String portName, int packet_size, boolean sim) throws IOException{
       return run(gui,portName,packet_size,sim,true);
   }

    /** Start a serial forwarder with the option of running in "Nido_Serial" mode */
    public static SerialForward run(boolean gui, String portName, int packet_size, boolean nidoSerial, boolean verbose) throws IOException{
       String s[] = new String[8];
        int i=0;
        s[i++]=new String("-comm");
        s[i++]=portName;
        s[i++]=new String("-packetsize");
        s[i++]=Integer.toString(packet_size);
        if(!gui) s[i++]=new String("-no-gui");
        if(nidoSerial) {
            s[i++]=new String("-source");
            s[i++]=new String("nido_serial");
          }
        if(!verbose) s[i++]=new String("-quiet");
        String s2[] = new String[i];
        for(int j=0;j<i;j++){
            s2[j]=s[j];
        }
        return new SerialForward(s2);
   }

    public void restart() {
      listener.RestartDataSource();
    }

    private void ProcessCommandLineArgs ( String[] args )
  {
    if ( debugMode ) {
      for ( int i = 0; i < args.length; i++)
      {
        System.err.println(args[i]);
      }
    }
    for ( int i = 0; i < args.length; i++ )
    {
      if ( args[i].equals ( "-no-gui") ) { guiMode = false; }
      else if (args[i].equals ("-comm" ) )
      {
        i++;
        if ( i < args.length ) {
		commPort = args[i];
		int idx = 0;
		if ((idx = commPort.indexOf(':')) > 0) {
			commPort_is_socket = true;
			commHost = commPort.substring(0, idx);
			commTCPPort = commPort.substring(idx+1, commPort.length());
		}
	} else { displayHelp = true; }
      }
      else if (args[i].equals ("-dbuser" ) )
      {
        i++;
        if ( i < args.length ) { strDBUser = args[i]; }
        else { displayHelp = true; }
      }
      else if (args[i].equals ("-dbpassword" ) )
      {
        i++;
        if ( i < args.length ) { strDBPassword = args[i]; }
        else { displayHelp = true; }
      }
      else if (args[i].equals ("-port" ) )
      {
        i++;
        if ( i < args.length ) { serverPort = Integer.parseInt(args[i]); }
        else { displayHelp = true; }
      }
      else if ( args[i].equals ("-packetsize") )
      {
        i++;
        if ( i < args.length ) { PACKET_SIZE = Integer.parseInt(args[i]); }
        else { displayHelp = true; }
      }
      else if ( args[i].equals ("-baud") )
      {
        i++;
        if ( i < args.length ) { BAUD_RATE = Integer.parseInt(args[i]); }
        else { displayHelp = true; }
      }
      else if ( args[i].equals ("-log") )
      {
	  bLogDB = true;
      }
      else if ( args[i].equals ("-quiet") ) { verboseMode = false; }
      else if ( args[i].equals ("-debug") ) { debugMode = true; }
      else if ( args[i].equals ("-source") )
      {
        i++;
	bNidoSerialData = false;
	bSourceSim = false;
	useDummyData = false;
	bSourceDB = false;
	bPostgresql = false;

        if ( i < args.length )
        {
            if ( args[i].equals("sim") )
            {
                bSourceSim = true;
                useDummyData = false;
		dataSource = new SimSource (this );
            }
	    else if ( args[i].equals("nido_serial") )
	    {
		bNidoSerialData = true;
		useDummyData = false;
		dataSource = new NidoSerialDataSource (this );
	    }
	    else if (args[i].equals ("dummy") )
            {
                useDummyData = true;
                dataSource = new DummySource (this);
            }
            else if (args[i].equals ("serial") )
            {
		// default
            }
	    else if (args[i].equals ("postgresql") )
	    {
		bSourceDB = true;
		bPostgresql = true;
	    }
	    else if (args[i].equals ("mysql") )
	    {
		bSourceDB = true;
	    }
            else {
                displayHelp = true;
            }
        }
      }
      else { displayHelp = true; }
    }
  }

  private static void PrintHelp ( )
  {
      System.err.println ("optional arguments:");
      System.err.println ("-comm [serial port name|host:port]");
      System.err.println ("-port [server port]");
      System.err.println ("-baud [rate in bps, default=19200]");
      System.err.println ("-packetsize [size]");
      System.err.println ("-no-gui      = do not display graphic interface");
      System.err.println ("-quiet       = non-verbose mode");
      System.err.println ("-debug       = display debug messages");
      System.err.println ("-source [nido_serial|sim|serial|dummy|postgres|mysql]");
      System.err.println ("-log         = log to database");
  }

  private void CreateGui ( )
  {
      JFrame mainFrame = new JFrame("SerialForwarder");
      cntrlWndw = new ControlWindow(this);
      mainFrame.setSize( cntrlWndw.getPreferredSize() );
      mainFrame.getContentPane().add("Center", cntrlWndw);
      mainFrame.show();
      mainFrame.addWindowListener ( cntrlWndw );
      cntrlWndw.ServerStart();
  }

    private void RunListenServer ( ) {
      listener = new ListenServer (this );
      listener.start();
    }

    public void ReportMessage ( String message )
    {
        if ( cntrlWndw != null )
        {
            cntrlWndw.AddMessage( message + "\n" );
        }
        else
        {
            System.err.println ( message );
        }
    }
    public void DEBUG ( String msg )
    {
        if ( debugMode ) { ReportMessage ( msg ); }
    }

    public void VERBOSE ( String msg )
    {
        if ( verboseMode ) { ReportMessage ( msg ); }
    }

    public void IncrementPacketsRead ( )
    {
        nPacketsRead++;
        if ( cntrlWndw != null ) { cntrlWndw.UpdatePacketsRead( nPacketsRead ); }
    }
    public void IncrementPacketsWritten ( )
    {
        nPacketsWritten++;
        if ( cntrlWndw != null ) { cntrlWndw.UpdatePacketsWritten ( nPacketsWritten ); }
    }
    public void IncrementClients ( )
    {
        nClients++;
        if ( cntrlWndw != null ) { cntrlWndw.UpdateNumClients( nClients ); }
    }
    public void DecrementClients ( )
    {
        nClients--;
        if ( cntrlWndw != null ) { cntrlWndw.UpdateNumClients( nClients ); }
    }

    public synchronized boolean InitSerialPortIO () {
            if (serialPortIO == null) {
                serialPortIO = new SerialPortIO(this);
                serialPortIO.start();
            }
            if( serialPortIO!=null)  {
                return true;      }
            else                 {
                return false;      }
        }

}
