/** * Copyright (c) 2003 - The Ohio State University. * All rights reserved. * * Permission to use, copy, modify, and distribute this software and its * documentation for any purpose, without fee, and without written agreement is * hereby granted, provided that the above copyright notice, the following * two paragraphs, and the author attribution appear in all copies of this * software. * * IN NO EVENT SHALL THE OHIO STATE UNIVERSITY BE LIABLE TO ANY PARTY FOR * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE OHIO STATE * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. * * THE OHIO STATE UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES, * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS * ON AN "AS IS" BASIS, AND THE OHIO STATE UNIVERSITY HAS NO OBLIGATION TO * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS. */

/*
*
*   FILE NAME
*
*        MoteReading.java
*
*   DESCRIPTION
*
*   This class implements the dynamic data elements of a Mote. These
*  will change over time, and every mote will have a vector of these.
*
*  Author : Adnan Vora  -  Kent State University
*
*  Modification history
*
*  4/19/2003  Mark E. Miyashita - Added parentMoteID along with get and set methods
*  4/25/2003  Adnan Vora - Added a custom 'clone' method
*
*/
public class MoteReading implements Cloneable {
   private int moteID;
   private long timestamp;
   private int magnetometerReading;
   private int MIRReading;
   private int batteryReading;
   private int parentMoteID;

  /**
	* historical values start
	* For use by the playback module only
	* Will be populated and read by the playback module
	*/
	private MoteReading lastReadingForThisMote;
	/* historical values end */

	public static final String ClassName = new String( "MoteReading" );

   public MoteReading() {
   }

   public MoteReading( int id, long time, int magRead, int MIRRead, int batRead, int parentID ) {
      this.setMoteID( id );
      this.setTimestamp( time );
      this.setMagnetometerReading( magRead );
      this.setMIRReading( MIRRead );
      this.setBatteryReading( batRead );
      this.setParentMoteID( parentID );
   }

   public int getMoteID() { return this.moteID; }
   public void setMoteID( int newMoteID ) { this.moteID = newMoteID; }

   public long getTimestamp() { return this.timestamp; }
   public void setTimestamp( long newTimestamp ) { this.timestamp = newTimestamp; }

   public int getMagnetometerReading() { return this.magnetometerReading; }
   public void setMagnetometerReading( int newMagnetometerReading ) { 
      this.magnetometerReading = newMagnetometerReading; 
   }

   public int getMIRReading() { return this.MIRReading; }
   public void setMIRReading( int newMIRReading ) { 
      this.MIRReading = newMIRReading; 
   }

   public int getBatteryReading() { return this.batteryReading; }
   public void setBatteryReading( int newBatteryReading ) { 
      this.batteryReading = newBatteryReading; 
   }

   public int getParentMoteID() { return this.parentMoteID; }
   public void setParentMoteID( int newMoteID ) { this.parentMoteID = newMoteID; }

	/**
	 * Populating historical values 
	 * */
   public MoteReading getLastReadingForThisMote() { return this.lastReadingForThisMote; }
   public void setLastReadingForThisMote( MoteReading newLastReadingForThisMote ) { 
      this.lastReadingForThisMote = newLastReadingForThisMote; 
   }

   public String toString() {
      return( "Timestamp: " + this.getTimestamp() + "\nMag.: "
               + this.getMagnetometerReading() + "\nMIR: "
               + this.getMIRReading() + "\nPower: "
               + this.getBatteryReading() );
   }

	public Object clone() {
		try {
			return super.clone();
		} catch ( CloneNotSupportedException cnse ) {
		}
		return null;
	}
}
