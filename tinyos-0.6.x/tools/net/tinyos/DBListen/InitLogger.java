/* -*-Mode: C; c-file-style: "BSD" -*-					       	tab:4
 *
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
 * $Id: InitLogger.java,v 1.5 2002/07/09 06:38:19 whong Exp $
 */

package net.tinyos.DBListen;

import java.io.*;
import javax.swing.*;

public class InitLogger {

    // flags used during client start-up
    public static boolean       guiMode        = true;
    public static boolean       displayHelp    = false;
    public static boolean       debugMode      = false;
    public static boolean       verboseMode    = true;
    public static int           PACKET_SIZE    = 36;
    public static int           serverPort     = 9000;
    public static String        server         = "127.0.0.1";
    public static String        strFileName    = "serialportlog.bin";

	public static String pgHost = "localhost";
	public static String dbName = "gdi";


    public static void main(String[] args) throws IOException {

	ProcessCommandLineArgs ( args );

	if ( displayHelp )
	{
	    PrintHelp ();
	}
	else if ( guiMode )
	{
	    if ( debugMode ) System.out.println ("Starting in GUI mode\n");
	    CreateGui();
	}
	else
	{
	    // no gui, user command line
	    if ( debugMode ) System.out.println ("Starting in GUI mode\n");
	    RunClient();
	}
    }

    private static void ProcessCommandLineArgs ( String[] args ) {

	for ( int i = 0; i < args.length; i++ )
	{
	    if ( args[i].equals ( "-no-gui") ) { guiMode = false; }
	    else if (args[i].equals ("-server" ) )
	    {
		i++;
		if ( i < args.length ) { server = args[i]; }
		else { displayHelp = true; }
	    }
	    else if (args[i].equals ("-file" ) )
	    {
		i++;
		if ( i < args.length ) { strFileName = args[i]; }
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
	    else if ( args[i].equals ("-debug") ) { debugMode = true; }
	    else if ( args[i].equals ("-no-verbose") ) { verboseMode = false; }
		else if (args[i].equals ("-dbname"))
		{
			i++;
			dbName = args[i];
		}
		else if (args[i].equals ("-pghost"))
		{
			i++;
			pgHost = args[i];
		}
	    else { displayHelp = true; }
	}
    }

    private static void PrintHelp ( ) {
	System.out.println ("optional arguments:");
	System.out.println ("-server [server address]");
	System.out.println ("-port [server port]");
	System.out.println ("-file [file name] ");
	System.out.println ("-dbname [database name] ");
	System.out.println ("-pghost [ip addr or dns name for PostgreSQL server] ");
	System.out.println ("-no-gui      = do not display graphic interface");
	System.out.println ("-debug       = display debug output");
	System.out.println ("-no-verbose  = do not display any textual output");
    }

    private static void CreateGui ( ) {
	// create frame
	JFrame clientFrame = new JFrame("Postgress Database Logger");
	// create client gui
	ClientWindow clntWindow = new ClientWindow ( );
	// create comm processing thread
	clientFrame.addWindowListener( clntWindow );
	clientFrame.setSize( clntWindow.getPreferredSize() );
	clientFrame.getContentPane().add("Center", clntWindow);
	clientFrame.show();
    }

    private static void RunClient ( ) {
	Logger client = new Logger ( null );
	client.start();
    }
}
