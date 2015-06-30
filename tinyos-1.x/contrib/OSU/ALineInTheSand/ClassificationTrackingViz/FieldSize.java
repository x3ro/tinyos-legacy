/** * Copyright (c) 2003 - The Ohio State University. * All rights reserved. * * Permission to use, copy, modify, and distribute this software and its * documentation for any purpose, without fee, and without written agreement is * hereby granted, provided that the above copyright notice, the following * two paragraphs, and the author attribution appear in all copies of this * software. * * IN NO EVENT SHALL THE OHIO STATE UNIVERSITY BE LIABLE TO ANY PARTY FOR * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE OHIO STATE * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. * * THE OHIO STATE UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES, * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS * ON AN "AS IS" BASIS, AND THE OHIO STATE UNIVERSITY HAS NO OBLIGATION TO * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS. */

/**
 *
 * FILE NAME
 *
 *     FieldSize.java
 *
 * DESCRIPTION
 *
 * The "FieldSize" standard MBean expose attributes and  
 * operations for management by implementing its corresponding  
 * "FieldSizeMBean" management interface. This MBean has one
 * attribute and three operations exposed for management by a JMX
 * agent:
 *       - the read/write "message" attribute,
 *       - the "LoadFieldSize()",
 *	   - the "printMessage()" operation.
 *
 * Author :  Mark E. Miyashita  -  Kent State Univerisity
 *
 * Modification history:
 *
 * 04/20/2003 Mark E. Miyashita - Created the intial interface
 *
 */

// RI imports

import javax.management.*;

// java imports

import java.io.*;
import java.util.*;

public class FieldSize extends NotificationBroadcasterSupport implements FieldSizeMBean
{
 /*
  * ------------------------------------------
  *  CONSTRUCTORS
  * ------------------------------------------
  */

  public FieldSize()
  {
    this.message = "FieldSize Constructor Called";
  }

  public FieldSize( String message )
  {
    this.message = message;
  }

 /*
  * -----------------------------------------------------
  * IMPLEMENTATION OF THE FieldSizeMBean INTERFACE
  * -----------------------------------------------------
  */

 /** 
  * Setter: set the "message" attribute of the "FieldSize" MBean.
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
  * Getter: set the "message" attribute of the "FieldSize" MBean.
  *
  * @return the current value of the "message" attribute.
  */

  public String getDisplayMessage()
  {
    return message;
  }

 /**
  * Operation: print the current values of "message" attributes of the 
  * "FieldSize" MBean.
  */

  public void printMessage()
  {
    System.out.println( message );
  }

 /**
  * Operation: read the Field Size information from the file 
  * Assumes input file name is called "Field_Size.dat" and
  * delimited by comma
  */

  public void LoadFieldSize()
  {
  /**
   * Open file to read mote coordinates
   */
   String motePosition;
   String delimiter = new String( "," );  /* Comma dlimited file */
   try
   {
   BufferedReader brIn = new BufferedReader(new InputStreamReader( new FileInputStream("field_size.dat")));
   while( ( motePosition = brIn.readLine() ) != null  ) {
         StringTokenizer parsePosition = new StringTokenizer( motePosition, delimiter );
         if( parsePosition.countTokens() >= 3 )
            {
             int FieldSizeX = Integer.parseInt( parsePosition.nextToken() );
             int FieldSizeY = Integer.parseInt( parsePosition.nextToken() );
             Field newFieldSize = new Field(FieldSizeX, FieldSizeY);
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
   Notification notification = new Notification( "readFieldSize", this, -1, System.currentTimeMillis(), "Field Size read" );

   /* Allow receiver of notification to access vector of mote object */
   notification.setUserData( newFieldSize );

   /* Send Notification */
   sendNotification( notification );

  }

 /*
  * -----------------------------------------------------
  * ATTRIBUTE ACCESSIBLE FOR MANAGEMENT BY A JMX AGENT
  * -----------------------------------------------------
  */

  private String message;

  private Field newFieldSize;

}