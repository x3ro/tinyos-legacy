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
  public static ControlWindow cntrlWndw         = null;
  public static DataSource    dataSource        = null;

  public static boolean       verboseMode       = false;
  public static boolean       debugMode         = false;
  public static boolean       useDummyData      = false;
  public static boolean       bSourceSim        = false;
    public static boolean bLogDB = false;
    public static boolean bSourceDB = false;

  //public static final int       TOSSIM_LISTENPORT  = 16778;
  public static final int       TOSSIM_LISTENPORT  = 10582;
  public static final String    TOSSIM_ADDRESS     = "127.0.0.1";
  //public static final int       TOSSIM_WRITEPORT    = 16779;
  public static final int       TOSSIM_WRITEPORT    = 10579;
  public static int           serverPort        = 9000;
  public static String        commPort          = "COM1";
  public static boolean	      commPort_is_socket = false;
  public static String	      commHost = null;
  public static String	      commTCPPort = null;

  public static int           PACKET_SIZE       = 36;
  public static byte[]        PACKET_DUMMY_DATA = new byte[PACKET_SIZE];

  private static boolean      guiMode           = true;
  private static boolean      displayHelp       = false;
  public static int           nBytesRead        = 0;
  private static int          nClients          = 0;
  private static int          nPacketsRead      = 0;
  private static int          nPacketsWritten   = 0;

    public static String strDBPassword = "";
    public static String strDBUser = "";
    public static boolean bPostgresql = false;

  public static void main(String[] args) throws IOException {

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
   public static void run(boolean gui, int packet_size) throws IOException{
	guiMode = gui;
	PACKET_SIZE = packet_size;
	
	//then run...
	main(new String[0]);
    }

  private static void ProcessCommandLineArgs ( String[] args )
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
      else if ( args[i].equals ("-log") )
      {
	  bLogDB = true;
      }
      else if ( args[i].equals ("-quiet") ) { verboseMode = false; }
      else if ( args[i].equals ("-debug") ) { debugMode = true; }
      else if ( args[i].equals ("-source") )
      {
        i++;
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
		dataSource = new SimSource ( );
            }
            else if (args[i].equals ("dummy") )
            {
                useDummyData = true;
                dataSource = new DummySource ( );
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
      System.err.println ("-packetsize [size]");
      System.err.println ("-no-gui      = do not display graphic interface");
      System.err.println ("-quiet       = non-verbose mode");
      System.err.println ("-debug       = display debug messages");
      System.err.println ("-source [sim|serial|dummy|postgres|mysql]");
      System.err.println ("-log         = log to database");
  }

  private static void CreateGui ( )
  {
      JFrame mainFrame = new JFrame("SerialForwarder");
      cntrlWndw = new ControlWindow();
      mainFrame.setSize( cntrlWndw.getPreferredSize() );
      mainFrame.getContentPane().add("Center", cntrlWndw);
      mainFrame.show();
      mainFrame.addWindowListener ( cntrlWndw );
      cntrlWndw.ServerStart();
  }

    private static void RunListenServer ( )
    {
    ListenServer listener = new ListenServer ( );
    listener.start();
    }

    public static void ReportMessage ( String message )
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
    public static void DEBUG ( String msg )
    {
        if ( debugMode ) { ReportMessage ( msg ); }
    }

    public static void VERBOSE ( String msg )
    {
        if ( verboseMode ) { ReportMessage ( msg ); }
    }

    public static void IncrementPacketsRead ( )
    {
        nPacketsRead++;
        if ( cntrlWndw != null ) { cntrlWndw.UpdatePacketsRead( nPacketsRead ); }
    }
    public static void IncrementPacketsWritten ( )
    {
        nPacketsWritten++;
        if ( cntrlWndw != null ) { cntrlWndw.UpdatePacketsWritten ( nPacketsWritten ); }
    }
    public static void IncrementClients ( )
    {
        nClients++;
        if ( cntrlWndw != null ) { cntrlWndw.UpdateNumClients( nClients ); }
    }
    public static void DecrementClients ( )
    {
        nClients--;
        if ( cntrlWndw != null ) { cntrlWndw.UpdateNumClients( nClients ); }
    }
}
