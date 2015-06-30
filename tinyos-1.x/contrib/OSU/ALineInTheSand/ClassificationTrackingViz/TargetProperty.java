/** * Copyright (c) 2003 - The Ohio State University. * All rights reserved. * * Permission to use, copy, modify, and distribute this software and its * documentation for any purpose, without fee, and without written agreement is * hereby granted, provided that the above copyright notice, the following * two paragraphs, and the author attribution appear in all copies of this * software. * * IN NO EVENT SHALL THE OHIO STATE UNIVERSITY BE LIABLE TO ANY PARTY FOR * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE OHIO STATE * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. * * THE OHIO STATE UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES, * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS * ON AN "AS IS" BASIS, AND THE OHIO STATE UNIVERSITY HAS NO OBLIGATION TO * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS. */

/*
*
*   FILE NAME
*
*        TargetProperty.java
*
*   DESCRIPTION
*
*   This class implements method used to handle target informatino generated from
*   the traget reading.  For each target detected, this class will store information
*   passed by the target message.  Below is the list of obeject format.
*
*  TargetMessage
*
*  -- Message Type
*  -- timestamp
*  -- id
*  -- type, int (0 - unidentified, 1 - soldier, 2 - tank, 3 - car...)
*  -- X coord
*  -- Y coord
*  -- target speed (meters per second)
*
*  Author : Adnan Vora, Mark E. Miyashita  -  Kent State University
*
*  Modification History:
*  1. 6/5/03 Mark E. Miyashita
*   - Added header to this file with comments
*     - Added Vector of mote IDs to store list of participated mote target detection
*     - Added additional methods related to Dispersion Overlay functionality
*  2. 6/8/03 Adnan Vora
*     - Added additional target type for Car
*
*/

/* Import required class files */
import java.util.*;

public class TargetProperty {
   private int targetID;
   private int targetX;
   private int targetY;
   private long timestamp;
   private int targetType;
   private int speed;
   private Vector vctMoteList = new Vector();
   public static final int SOLDIER = 1;
   public static final int HUMAN = 9;
   public static final int TANK = 3;
   public static final int CAR = 2;
   public static final String ClassName = new String( "TargetProperty" );

   public TargetProperty(int newID, int newX, int newY, long time, int newType, int newSpeed) {
      this.setTargetID( newID );
      this.setTargetX( newX );
      this.setTargetY( newY );
      this.setTimestamp( time );
      this.setTargetType( newType );
      this.setSpeed( newSpeed );
   }

   public void addMoteList( int moteID ) {
          vctMoteList.add( new Integer(moteID) );
   }
   public void removeMoteList() { vctMoteList.removeAllElements(); }
   public int getMoteListSize() { return vctMoteList.size(); }
   public Vector getMoteList() { return vctMoteList; }
   public int getMoteListelementAt( int i ) { return Integer.valueOf(vctMoteList.elementAt(i).toString()).intValue(); }
   public void removeMoteListElement( int pos ) { vctMoteList.removeElementAt(pos); }
   public boolean CheckMoteList( int ID ) {
      int size = getMoteListSize();
      for (int i = 0; i < size; i++)
         if ( ID == getMoteListelementAt(i) ) return true;
      return false;
   }

   public int getTargetID() { return this.targetID; }
   public void setTargetID( int newID ) { this.targetID = newID; }

   public int getTargetX() { return this.targetX; }
   public void setTargetX( int newX ) { this.targetX = newX; }

   public int getTargetY() { return this.targetY; }
   public void setTargetY( int newY ) { this.targetY = newY; }

   public long getTimestamp() { return this.timestamp; }
   public void setTimestamp( long time ) { this.timestamp = time; }

   public int getTargetType() { return this.targetType; }
   public void setTargetType( int newType ) { this.targetType = newType; }

   public String getTargetName() {
      String targetName = null;

      switch( getTargetType() ) {
         case TargetProperty.SOLDIER :
            targetName = new String( "Soldier" );
            break;
         case TargetProperty.HUMAN :
            targetName = new String( "Human" );
            break;
         case TargetProperty.TANK :
            targetName = new String( "Tank" );
            break;
         case TargetProperty.CAR :
            targetName = new String( "Car" );
            break;
         default :
            targetName = new String( "Unknown" );
      }
      return targetName;
   }

   public int getSpeed() { return this.speed; }
   public void setSpeed( int newSpeed ) { this.speed = newSpeed; }

   public String toString() {
      return( "#" + getTargetID() + "(" + getTargetX() + ", " + getTargetY() +
         ")\nType: " + getTargetName() + "\nSpeed: " + getSpeed() + "\nTime: " + getTimestamp() );
   }
}
