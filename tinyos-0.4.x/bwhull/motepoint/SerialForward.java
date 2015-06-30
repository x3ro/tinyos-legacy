/**
 * File: SerialForward.java
 *
 * Description:
 * The SerialForward class provides many static functions
 * that handle the initialization of the serialforwarder
 * and/or the associated gui.
 *
 * Author: Bret Hull
 */

import java.io.*;
import javax.swing.*;
import java.awt.event.*;

public class SerialForward {

  // appication defaults
  public static ControlWindow cntrlWndw         = null;

  public static boolean       verboseMode       = true;
  public static boolean       debugMode         = true;
  public static boolean       useDummyData      = true;
  public static boolean       bSourceSim        = false;

  public static final int       TOSSIM_LISTENPORT  = 16778;
  public static final String    TOSSIM_ADDRESS     = "127.0.0.1";
  public static final int       TOSSIM_WRITEPORT    = 16779;
  public static int           serverPort        = 9000;
  public static String        commPort          = "/dev/ttyS0";

  public static int           PACKET_SIZE       = 30;
  public static byte[]        PACKET_DUMMY_DATA = new byte[PACKET_SIZE];

  private static boolean      guiMode           = true;
  private static boolean      displayHelp       = false;
  public static int           nBytesRead        = 0;
  private static int          nClients          = 0;
  private static int          nPacketsRead      = 0;

  public static void main(String[] args) throws IOException {

    System.out.println( "Initializing MotePoint Server 1.0" );
    ProcessCommandLineArgs ( args );

    if ( displayHelp )
    {
      PrintHelp ();
    }
    else if ( guiMode )
    {
      System.out.println("Starting in GUI mode\n");
      CreateGui();
    }
    else {
      // no gui, user command line
      RunListenServer();
    }
  }

  private static void ProcessCommandLineArgs ( String[] args )
  {
    if ( debugMode ) {
      for ( int i = 0; i < args.length; i++)
      {
        System.out.println(args[i]);
      }
    }
    for ( int i = 0; i < args.length; i++ )
    {
      if ( args[i].equals ( "-no-gui") ) { guiMode = false; }
      else if (args[i].equals ("-comm" ) )
      {
        i++;
        if ( i < args.length ) { commPort = args[i]; }
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
      else if ( args[i].equals ("-quiet") ) { verboseMode = false; }
      else if ( args[i].equals ("-debug") ) { debugMode = true; }
      else if ( args[i].equals ("-source") )
      {
        i++;
        if ( i < args.length )
        {
            if ( args[i].equals("sim") )
            {
                bSourceSim = true;
                useDummyData = false;
            }
            else if (args[i].equals ("dummy") )
            {
                bSourceSim = false;
                useDummyData = true;
                for (int ii = 0; ii < PACKET_DUMMY_DATA.length; ii++)
                {
                    PACKET_DUMMY_DATA[ii] = (byte)1;
                }
            }
            else if (args[i].equals ("serial") )
            {
                bSourceSim = false;
                useDummyData = false;
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
      System.out.println ("optional arguments:");
      System.out.println ("-comm [serial port]");
      System.out.println ("-port [server port]");
      System.out.println ("-packetsize [size]");
      System.out.println ("-no-gui      = do not display graphic interface");
      System.out.println ("-quiet       = non-verbose mode");
      System.out.println ("-debug       = display debug messages");
      System.out.println ("-source [sim|serial|dummy]");

  }

  private static void CreateGui ( )
  {
      JFrame mainFrame = new JFrame("MotePoint Server");
      cntrlWndw = new ControlWindow();
      mainFrame.setSize( cntrlWndw.getPreferredSize() );
      mainFrame.getContentPane().add("Center", cntrlWndw);
      mainFrame.show();
      mainFrame.addWindowListener ( cntrlWndw );
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
            System.out.println ( message );
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
    public static void DecrementPacketsRead ( )
    {
        nPacketsRead--;
        if ( cntrlWndw != null ) { cntrlWndw.UpdatePacketsRead( nPacketsRead ); }
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
