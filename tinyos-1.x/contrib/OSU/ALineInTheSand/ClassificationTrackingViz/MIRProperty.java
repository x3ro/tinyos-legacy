/** * Copyright (c) 2003 - The Ohio State University. * All rights reserved. * * Permission to use, copy, modify, and distribute this software and its * documentation for any purpose, without fee, and without written agreement is * hereby granted, provided that the above copyright notice, the following * two paragraphs, and the author attribution appear in all copies of this * software. * * IN NO EVENT SHALL THE OHIO STATE UNIVERSITY BE LIABLE TO ANY PARTY FOR * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE OHIO STATE * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. * * THE OHIO STATE UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES, * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS * ON AN "AS IS" BASIS, AND THE OHIO STATE UNIVERSITY HAS NO OBLIGATION TO * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS. */

/*
*
*   FILE NAME
*
*        MIRProperty.java
*
*   DESCRIPTION
*
*   This class is used as the MIR message object
*
*  MIRMessage
*
*  -- Message Type
*  -- timestamp
*  -- X coord
*  -- Y coord
*  -- radius
*
*  Author : Adnan Vora -  Kent State University
*
*  Modification History:
*
*/
public class MIRProperty {
	private int mirID;
   private int mirX;
   private int mirY;
   private long timestamp;
   private int mirType;
   private int radius;
   public static final int START = 0;
   public static final int END = 1;
   public static final String ClassName = new String( "MIRProperty" );

   public MIRProperty( int newID, int newX, int newY, int newType, int newRadius) {
		this.setID( newID );
      this.setMIRX( newX );
      this.setMIRY( newY );
      this.setMIRType( newType );
      this.setRadius( newRadius );
   }

   public int getID() { return this.mirID; }
   public void setID( int newID ) { this.mirID = newID; }

   public int getMIRX() { return this.mirX; }
   public void setMIRX( int newX ) { this.mirX = newX; }

   public int getMIRY() { return this.mirY; }
   public void setMIRY( int newY ) { this.mirY = newY; }

   public long getTimestamp() { return this.timestamp; }
   public void setTimestamp( long time ) { this.timestamp = time; }

   public int getMIRType() { return this.mirType; }
   public void setMIRType( int newType ) { this.mirType = newType; }

   public int getRadius() { return this.radius; }
   public void setRadius( int newRadius ) { this.radius = newRadius; }

   public String toString() {
      return( "MIR" + "(" + getMIRX() + ", " + getMIRY() +
         ")\nType: " + getMIRType() + "\nRadius: " + getRadius() + "\nTime: " + getTimestamp() );
   }
}
