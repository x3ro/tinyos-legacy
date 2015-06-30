/** * Copyright (c) 2003 - The Ohio State University. * All rights reserved. * * Permission to use, copy, modify, and distribute this software and its * documentation for any purpose, without fee, and without written agreement is * hereby granted, provided that the above copyright notice, the following * two paragraphs, and the author attribution appear in all copies of this * software. * * IN NO EVENT SHALL THE OHIO STATE UNIVERSITY BE LIABLE TO ANY PARTY FOR * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE OHIO STATE * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. * * THE OHIO STATE UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES, * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS * ON AN "AS IS" BASIS, AND THE OHIO STATE UNIVERSITY HAS NO OBLIGATION TO * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS. */

import java.net.*; 
import java.util.*;
import java.io.*;

public class SocketServer extends Thread { 

   private int PORT = 10577;
   private Thread thread;
   private ServerSocket s; 
   private DataOutputStream output = null;
   private InputStream input = null;
   private boolean Shutdown = false;
   private static final int TARGETMESSAGE = 1;      /* target message type */
   private static final int MOTEMESSAGE = 2;        /* mote message type */
   private boolean stop = false;                    /* file read control variable */ 

   public SocketServer() {
 
        super();
        start();

   }

   public void start() {

        thread = new Thread(this);
        thread.setPriority(Thread.MIN_PRIORITY);
        thread.start();

    }

   public void run() {

        // open up our server socket
        try { 
              s = new ServerSocket(PORT); 
	        System.out.println("ready to accept connectinos");
        }
        catch (IOException e)
        {
            System.out.println("Could not listen on port: " + PORT);
            Shutdown = true;
        }
        try {
            Socket currentSocket;
            while (!Shutdown)
            {   
                currentSocket = s.accept();
                System.out.println("Got new connection");
                try
                   {
                     input = currentSocket.getInputStream();
                     output = new DataOutputStream(currentSocket.getOutputStream());
                   }
                catch ( Exception e )
                   {   
                     e.printStackTrace();
                     Shutdown = true;
                   }
                WritePacket();
            }
            try { 
                  input.close();
                  output.close();
                  s.close(); 
            } catch ( IOException e ) { e.printStackTrace(); }
        }
        catch ( IOException e) {
            System.out.println("Server Socket closed");
        }
    }


    private void WritePacket ()
    {

    long timestamp = 0; 
    String motePosition;
    String delimiter = new String( "," );  /* Comma dlimited file */

    while( !stop )
    {
     try
     {
       BufferedReader brIn = new BufferedReader(new InputStreamReader( new FileInputStream("mote_message.dat")));
       while( ( ( motePosition = brIn.readLine() ) != null  ) && ( !stop ) ) {
        StringTokenizer parsePosition = new StringTokenizer( motePosition, delimiter );
         if( parsePosition.countTokens() >= 3 )
            {

 	       byte[] data = new byte[6];

             data[0] = (byte)(Integer.parseInt( parsePosition.nextToken(), 16) & 0xff );

             if ( (int)(data[0]) == MOTEMESSAGE ) {
                try {
                   data[1] = (byte)(Integer.parseInt( parsePosition.nextToken(), 16) & 0xff );
                   timestamp = System.currentTimeMillis();
                   data[2] = (byte)(Integer.parseInt( parsePosition.nextToken(), 16) & 0xff );
                   data[3] = (byte)(Integer.parseInt( parsePosition.nextToken(), 16) & 0xff );
                   data[4] = (byte)(Integer.parseInt( parsePosition.nextToken(), 16) & 0xff );
                   data[5] = (byte)(Integer.parseInt( parsePosition.nextToken(), 16) & 0xff );
                 }
			catch (NumberFormatException e) {
			    System.out.println(e);
		     }
 
                output.writeLong(timestamp);
                output.write(data);
               
                try
                {
                  Thread.sleep( 20 );
                }
                 catch( Exception e )
                {
                   e.printStackTrace();
                }
             } else if ( (int)(data[0]) == TARGETMESSAGE ) {
                try {
                    data[1] = (byte)(Integer.parseInt( parsePosition.nextToken(),16) & 0xff );
                    timestamp = System.currentTimeMillis();
                    data[2] = (byte)(Integer.parseInt( parsePosition.nextToken(),16) & 0xff );
                    data[3] = (byte)(Integer.parseInt( parsePosition.nextToken(),16) & 0xff );
                    data[4] = (byte)(Integer.parseInt( parsePosition.nextToken(),16) & 0xff );
                    data[5] = (byte)(Integer.parseInt( parsePosition.nextToken(),16) & 0xff );
	    	     }
			 catch (NumberFormatException e) {
			     System.out.println(e);
		     }
 
                output.writeLong(timestamp);
                output.write(data);

               try
                {
                  Thread.sleep( 20 );
                }
                 catch( Exception e )
                {
                   e.printStackTrace();
                }
             }
 
           }
       }
     /* Close inout stream */
     brIn.close();

    } catch( FileNotFoundException fnfe ) {
        fnfe.printStackTrace();
    } catch( IOException ioe ) {
        ioe.printStackTrace();
    } catch( Exception exc ) {
        exc.printStackTrace();
    }  
    stop = true;    
    }

   }

   public static void main(String args[]) {

      SocketServer ss = new SocketServer();

   }
  
}








