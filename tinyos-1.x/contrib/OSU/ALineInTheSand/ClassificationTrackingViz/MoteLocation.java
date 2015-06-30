/** * Copyright (c) 2003 - The Ohio State University. * All rights reserved. * * Permission to use, copy, modify, and distribute this software and its * documentation for any purpose, without fee, and without written agreement is * hereby granted, provided that the above copyright notice, the following * two paragraphs, and the author attribution appear in all copies of this * software. * * IN NO EVENT SHALL THE OHIO STATE UNIVERSITY BE LIABLE TO ANY PARTY FOR * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE OHIO STATE * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. * * THE OHIO STATE UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES, * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS * ON AN "AS IS" BASIS, AND THE OHIO STATE UNIVERSITY HAS NO OBLIGATION TO * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS. */

/**
 *
 * FILE NAME
 *
 *     MoteLocation.java
 *
 * DESCRIPTION
 *
 * The "MoteLocation" standard MBean expose attributes and  
 * operations for management by implementing its corresponding  
 * "MoteLocationMBean" management interface. This MBean has one
 * attribute and three operations exposed for management by a JMX
 * agent:
 *       - the read/write "message" attribute,
 *       - the "readMoteLocation()",
 *       - the "clearMoteLocation()",
 *	   - the "printDisplayMessage()" operation.
 *
 * Author :  Mark E. Miyashita  -  Kent State Univerisity
 *
 * Modification history:
 *
 * 04/18/2003 Mark E. Miyashita - Created the intial interface
 * 06/05/2003 Mark E. Miyashita - Added handling of Scale object and notification
 *
 */

// RI imports

import javax.management.*;

// java imports

import java.io.*;
import java.util.*;

public class MoteLocation extends NotificationBroadcasterSupport implements MoteLocationMBean
{
 /*
  * ------------------------------------------
  *  CONSTRUCTORS
  * ------------------------------------------
  */

  public MoteLocation()
  {
    this.message = "MoteLocation Constructor Called";
  }

  public MoteLocation( String message )
  {
    this.message = message;
  }

 /*
  * -----------------------------------------------------
  * IMPLEMENTATION OF THE MoteLocationMBean INTERFACE
  * -----------------------------------------------------
  */

 /** 
  * Setter: set the "message" attribute of the "MoteLocation" MBean.
  *
  * @param <VAR>s</VAR> the new value of the "message" attribute.
  */

  public void setDisplayMessage( String message )
  {
    this.message = message;
    Notification notification = new Notification( "setDisplayMessage", this, -1, System.currentTimeMillis(), message );
    sendNotification( notification );
  }

 /**
  * Getter: set the "message" attribute of the "MoteLocation" MBean.
  *
  * @return the current value of the "message" attribute.
  */

  public String getDisplayMessage()
  {
    return message;
  }

 /**
  * Operation: print the current values of "message" attributes of the 
  * "MoteLocation" MBean.
  */

  public void printDisplayMessage()
  {
    System.out.println( message );
  }

 /**
  * Operation: read the mote location information from the file 
  * Assumes input file name is called "mote_coordinates.dat" and
  * delimited by comma
  */

  public void readMoteLocation()
  {
  /**
   * Open file to read mote coordinates
   */
   String motePosition;
   String delimiter = new String( "," );  /* Comma dlimited file */
   boolean FirstLine = true;
   Scale newScale = new Scale();
   try
   {
   BufferedReader brIn = new BufferedReader(new InputStreamReader( new FileInputStream("mote_coordinates.dat")));
   while( ( motePosition = brIn.readLine() ) != null  ) {
         StringTokenizer parsePosition = new StringTokenizer( motePosition, delimiter );
         if (( FirstLine ) && ( parsePosition.countTokens() >= 3 ))
            {
             int offsetX = Integer.parseInt( parsePosition.nextToken() );
             int offsetY = Integer.parseInt( parsePosition.nextToken() );
             int factor = Integer.parseInt( parsePosition.nextToken() );
             newScale.setScale(offsetX, offsetY, factor);
             /* Create notification */  
             Notification notification = new Notification( "readScale", this, -1, System.currentTimeMillis(), "Scale information read" );
             /* Allow receiver of notification to access Scale object */
             notification.setUserData( newScale );
             /* Send Notification */
             sendNotification( notification );
             FirstLine = false;
            }
         else if (( !FirstLine ) && ( parsePosition.countTokens() >= 3 )) 
            {
             int moteId = Integer.parseInt( parsePosition.nextToken() );
             int moteX = newScale.getScaleFactor() * Integer.parseInt( parsePosition.nextToken() ) + newScale.getoffsetX();
             int moteY = newScale.getScaleFactor() * Integer.parseInt( parsePosition.nextToken() ) + newScale.getoffsetY();
             Mote newMote = new Mote(moteId, moteX, moteY);
             vctMotes.add(newMote);
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
 
   /* Create notification */  
   Notification notification = new Notification( "readMoteLocation", this, -1, System.currentTimeMillis(), "Mote Location read" );

   /* Allow receiver of notification to access vector of mote object */
   notification.setUserData( vctMotes );

   /* Send Notification */
   sendNotification( notification );

  }

 /**
  * Operation: clear the mote location information from the vector 
  */

  public void clearMoteLocation()
  {
   this.vctMotes.removeAllElements();

   /* Create notification */  
   Notification notification = new Notification( "clearMoteLocation", this, -1, System.currentTimeMillis(), "Mote Location Cleared" );

   /* Send Notification */
   sendNotification( notification );

  }

 /*
  * -----------------------------------------------------
  * ATTRIBUTE ACCESSIBLE FOR MANAGEMENT BY A JMX AGENT
  * -----------------------------------------------------
  */

  private String message;

 /*
  * ---------------------------------------------------------------------------
  * PROPERTY ACCESSIBLE FOR MANAGEMENT ONLY THROUGH NOTIFICATION BY A JMX AGENT
  * ---------------------------------------------------------------------------
  */

  private Vector vctMotes  = new Vector();  /* Vector of Motes */

}