/** * Copyright (c) 2003 - The Ohio State University. * All rights reserved. * * Permission to use, copy, modify, and distribute this software and its * documentation for any purpose, without fee, and without written agreement is * hereby granted, provided that the above copyright notice, the following * two paragraphs, and the author attribution appear in all copies of this * software. * * IN NO EVENT SHALL THE OHIO STATE UNIVERSITY BE LIABLE TO ANY PARTY FOR * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE OHIO STATE * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. * * THE OHIO STATE UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES, * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS * ON AN "AS IS" BASIS, AND THE OHIO STATE UNIVERSITY HAS NO OBLIGATION TO * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS. */

import java.awt.* ;
import java.io.*;
import java.util.*;

public class Llinfo
{
        
    

    public static void storelocations(Moteinfo[] mote, int motes, int intervals)
    {
        String motePosition;
        String delimiter = new String( "," );  /* Comma dlimited file */
        
        try
        {
            BufferedReader brIn = new BufferedReader(new InputStreamReader(new FileInputStream("mote_coordinates.dat")));
            
            for (int i=1;i<=motes;i++)
                mote[i]=new Moteinfo(-1,-1,10,10,0,0,0);
            
            while( ( motePosition = brIn.readLine() ) != null  ) 
            {
                    StringTokenizer parsePosition = new StringTokenizer( motePosition, delimiter );
                    if( parsePosition.countTokens() >= 1 )
                        {
                            int id = Integer.parseInt( parsePosition.nextToken() );
                            int x = Integer.parseInt( parsePosition.nextToken() );
                            int y = Integer.parseInt( parsePosition.nextToken() );
                            mote[id] = new Moteinfo(x,y,10,10,0,0,0);
                            
                        }
            }
                /* Close inout stream */
                brIn.close();

        } 
        catch( FileNotFoundException fnfe ) 
        {
                fnfe.printStackTrace();
            }
        catch( IOException ioe ) 
        {
                ioe.printStackTrace();
        } 
        catch( Exception exc ) 
        {
                exc.printStackTrace();
        }
    }
}

    
