/** * Copyright (c) 2003 - The Ohio State University. * All rights reserved. * * Permission to use, copy, modify, and distribute this software and its * documentation for any purpose, without fee, and without written agreement is * hereby granted, provided that the above copyright notice, the following * two paragraphs, and the author attribution appear in all copies of this * software. * * IN NO EVENT SHALL THE OHIO STATE UNIVERSITY BE LIABLE TO ANY PARTY FOR * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE OHIO STATE * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. * * THE OHIO STATE UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES, * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS * ON AN "AS IS" BASIS, AND THE OHIO STATE UNIVERSITY HAS NO OBLIGATION TO * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS. */

/*
*
*   FILE NAME
*
*        Mote.java
*
*   DESCRIPTION
*
*   This class implements method used to handle Base Station mote object.  
*  It is intended to capture information on motes such as locatoin
* 
*  Author : Mark E. Miyashita, Adnan Vora  -  Kent State University
*
*  Modification History:
*  1. 4/22/03 - Mark E. Miyashita - Created initial file 
*
*/
public class BaseStationMote {
   private int moteID;
   private int moteX;    /* X and Y coordinates */
   private int moteY;
   private long timeOfLastUpdate;
   private boolean alive;
   private int parentMoteID;
   private MoteReading lastReading;
   private static int maxVectorSize = 512;
   private static int batteryThreshold = 1;

   public BaseStationMote() {
      this.setMoteID( 0 );
      this.setMoteX( 0 );
      this.setMoteY( 0 );
      this.setTimeOfLastUpdate( 0 );
      this.setAlive();
      this.setParentMoteID( -1 );
   }
   public BaseStationMote( int newID, int newX, int newY ) {
      this.setMoteID( newID );
      this.setMoteX( newX );
      this.setMoteY( newY );
      this.setTimeOfLastUpdate( 0 );
      this.setAlive();
      this.setParentMoteID( -1 );
   }

   public int getMoteID() { return this.moteID; }
   public void setMoteID( int newID ) { this.moteID = newID; }

   public int getMoteX() { return this.moteX; }
   public void setMoteX( int newX ) { this.moteX = newX; }

   public int getMoteY() { return this.moteY; }
   public void setMoteY( int newY ) { this.moteY = newY; }

   public void setMoteLocation( int id, int x, int y ) {
      this.setMoteID( id );
      this.setMoteX( x );
      this.setMoteY( y );
   }

   public long getTimeOfLastUpdate() { return this.timeOfLastUpdate; }
   public void setTimeOfLastUpdate( long newTimeOfLastUpdate ) { 
      this.timeOfLastUpdate = newTimeOfLastUpdate; 
   }

   public boolean isAlive() { return this.alive; }
   public boolean setAlive() { 
      if( lastReading != null ) {
         /*
         * Grab the last Reading for this mote, and check if the battery
         * reading is greater than the threshold. If not, declare the mote
         * to be dead
         */
         if( lastReading.getBatteryReading() > BaseStationMote.batteryThreshold ) {
            this.alive = true;
         }
         else {
            this.alive = false;
         }
      }
      else {
         /*
         * No readings were received, assume Mote is new and still alive
         */
         this.alive = true;
      }
      return this.alive;
   }

   public int getParentMoteID() { return this.parentMoteID; }
   public void setParentMoteID( int newParentMoteID ) { 
      this.parentMoteID = newParentMoteID; 
   }

   public MoteReading getLastReading() { return lastReading; }
   public void setLastReading( MoteReading newReading ) {
      lastReading = newReading;
   }

   public String toString() {
      return( "Base Station Mote #" + this.getMoteID() + ", Position: (" + this.getMoteX() +
               ", " + this.getMoteY() + ") Status: " + 
               ( this.isAlive() ? "Alive" : "Dead" )
               + " Parent: " + this.getParentMoteID() + " Last Updated at: " +
               this.getTimeOfLastUpdate() );
   }
}
