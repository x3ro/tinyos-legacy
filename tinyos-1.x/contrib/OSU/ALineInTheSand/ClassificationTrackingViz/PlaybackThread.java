/** * Copyright (c) 2003 - The Ohio State University. * All rights reserved. * * Permission to use, copy, modify, and distribute this software and its * documentation for any purpose, without fee, and without written agreement is * hereby granted, provided that the above copyright notice, the following * two paragraphs, and the author attribution appear in all copies of this * software. * * IN NO EVENT SHALL THE OHIO STATE UNIVERSITY BE LIABLE TO ANY PARTY FOR * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE OHIO STATE * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. * * THE OHIO STATE UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES, * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS * ON AN "AS IS" BASIS, AND THE OHIO STATE UNIVERSITY HAS NO OBLIGATION TO * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS. */

/*
* FILE NAME
*
*     PlaybackThread.java
*
* DESCRIPTION
*
*   This thread starts playback
*
* Author : Adnan Vora  - Kent State University
*
* Modification History
* 1. Adnan Vora (6/25/2003) - Changed playback logic
*          to be time-based instead of event based
* 2. Adnan Vora (6/27/2003) - Incorporated MIR Display
*
*/

import java.lang.*;
import java.util.*;

public class PlaybackThread implements Runnable {
   private GraphicsPanel gpanel;
   private ButtonPanel bpanel;
   private Thread thread;
   private boolean continueRun = true;
   private int playbackInterval = 15;
   private int messageRate = 50;

   public PlaybackThread( GraphicsPanel g, ButtonPanel b ) {
      this.gpanel = g;
      this.bpanel = b;
      continueRun = true;
   }

   public void start() {
      thread = new Thread(this);
      thread.setPriority(Thread.MIN_PRIORITY);
      thread.start();
   }

   /* Stop this Thread */
   public synchronized void stop() {
      try {            
         thread = null;
         notify();
      }catch(Exception e){
         e.printStackTrace();
      }
   }

   /* Execute this Thread */
   public void run() {
      continueRun = true;
      playback();
      bpanel.enablePlayback();
      bpanel.enableFreeze();
		gpanel.surf.setPlaybackStartTime( 0 );
      this.stop();
   }

   public void playback() {
      boolean playbackPeriodReached = false;
      long freezeTime = gpanel.surf.getFreezeTime();
      playbackInterval = gpanel.surf.getPlaybackTime();
		gpanel.surf.setPlaybackStartTime( System.currentTimeMillis() );
      long playbackStartTime = freezeTime - ( playbackInterval * 1000 );

      Vector copyVctReadingClone = (Vector)gpanel.surf.vctReadingClone.clone();
      Vector copyVctMotesClone = (Vector)gpanel.surf.vctMotesClone.clone();
      for( int i = 0; i < gpanel.surf.vctMotesClone.size(); i++ ) {
         Mote thisMote = (Mote)gpanel.surf.vctMotesClone.get( i );
         copyVctMotesClone.set( i, thisMote.clone() );
      }

      BitSet copyDisplayMIRClone = (BitSet)gpanel.surf.displayMIRClone.clone();
      /*
      int readingsNeeded = playbackInterval * messageRate;
      */
      int readingsCollected = copyVctReadingClone.size();
      /*
      int playbackStartPoint = readingsCollected - readingsNeeded + 1;
      playbackStartPoint = ( playbackStartPoint >= 0 ) ? playbackStartPoint : 0;
      */


      int playbackStartCtr = -1;
      long lastReadingTime = -1;
      for( int msgCtr = 0; msgCtr < copyVctReadingClone.size() && continueRun; 
msgCtr++ ) {
         Object currentObject = copyVctReadingClone.get( msgCtr );
         if( currentObject.getClass().getName().equals( MoteReading.ClassName ) 
) {
            MoteReading currReading = (MoteReading) currentObject;
            if( currReading.getTimestamp() >= playbackStartTime ) {
               gpanel.surf.vctReadingClone.remove( currentObject );
               if( playbackStartCtr < 0 ) {
                  playbackStartCtr = msgCtr;
               }
               if( lastReadingTime < 0 ) {
                  lastReadingTime = currReading.getTimestamp();
               }
            }
         }
         else if( currentObject.getClass().getName().equals( 
TargetProperty.ClassName ) ) {
            TargetProperty currProperty = (TargetProperty) currentObject;
            if( currProperty.getTimestamp() >= playbackStartTime ) {
               gpanel.surf.vctReadingClone.remove( currentObject );
               if( playbackStartCtr < 0 ) {
                  playbackStartCtr = msgCtr;
               }
               if( lastReadingTime < 0 ) {
                  lastReadingTime = currProperty.getTimestamp();
               }
            }
         }
         else {
            MIRProperty currProperty = (MIRProperty) currentObject;
            if( currProperty.getTimestamp() >= playbackStartTime ) {
               gpanel.surf.vctReadingClone.remove( currentObject );
               if( playbackStartCtr < 0 ) {
                  playbackStartCtr = msgCtr;
               }
               if( lastReadingTime < 0 ) {
                  lastReadingTime = currProperty.getTimestamp();
               }
            }
         }
      }

      if( playbackStartCtr < 0 ) {
         playbackStartCtr = 0;
      }
      if( lastReadingTime < 0 ) {
         Object currentObject = gpanel.surf.vctReadingClone.get( 0 );
         if( currentObject.getClass().getName().equals( MoteReading.ClassName ) 
) {
            MoteReading currReading = (MoteReading) currentObject;
            lastReadingTime = currReading.getTimestamp();
         }
         else if( currentObject.getClass().getName().equals( 
TargetProperty.ClassName ) ) {
            TargetProperty currProperty = (TargetProperty) currentObject;
            lastReadingTime = currProperty.getTimestamp();
         }
         else {
            MIRProperty currProperty = (MIRProperty) currentObject;
            lastReadingTime = currProperty.getTimestamp();
         }
      }
      // Remove all playback-able readings from orig vector
      // Since removeRange() is a "protected" method, we remove all entries
      // and add back the ones we shouldnt have removed
      /*
      gpanel.surf.vctReadingClone.removeAllElements();
      if( readingsCollected - readingsNeeded > 0 ) {
         gpanel.surf.vctReadingClone.addAll( copyVctReadingClone.subList( 0, 
playbackStartPoint ) );
      }
      */

      // Restore state of motes to as it was before playback point
      int numberOfMotes = gpanel.surf.vctMotesClone.size();
      int numberOfMotesRestored = 0;

      // Each mote should be restored at most once.. hence we keep track using
      // this BitSet
      BitSet moteStateRestored = new BitSet( gpanel.surf.vctMotesClone.size() );


      /**
      * To restore the state of motes, this is the logic used:
      * Quickly scan through all the readings _since_ the point when playback
      * is to begin. If we find a mote reading, then it will have within it the
      * last mote reading that it replaced. The first such MoteReadings for each
      * mote in the list of readings to be played back, we will find the old 
readings
      * for every mote. If such a reading does not exist, then it means that the 
state
      * of the mote as it was before the playback duration, is not going to 
change
      * during playback, so we are still good.
      * */
      for( int readingsCtr = playbackStartCtr;
               readingsCtr < readingsCollected && 
                  numberOfMotesRestored < numberOfMotes && continueRun;
               readingsCtr++ ) {
         Object currentObject = copyVctReadingClone.elementAt( readingsCtr );
         if( currentObject.getClass().getName().equals( 
                        MoteReading.ClassName ) ) {
            MoteReading currentReading = (MoteReading) currentObject;

            /**
            * If the mote corresponding to this reading has not already been
            * restored, then find the mote and restore it.
            * */
            if( !moteStateRestored.get( currentReading.getMoteID() ) ) {
               ListIterator newMotesIter = 
gpanel.surf.vctMotesClone.listIterator();
               while( newMotesIter.hasNext() ) {
                  Mote currentMote = (Mote)newMotesIter.next();
                  if( currentMote.getMoteID() == currentReading.getMoteID() ) {
                     currentMote.setLastReading( 
currentReading.getLastReadingForThisMote() );
                     // Fix ParentMoteID
                     if( currentReading.getLastReadingForThisMote() != null ) {
                        ListIterator parentMotesIter = 
gpanel.surf.vctMotesClone.listIterator();
                        Mote parentMote = null;
                        currentMote.setParentMote( null );
                        while( parentMotesIter.hasNext() ) {
                           parentMote = (Mote)parentMotesIter.next();
                           if( parentMote.getMoteID() == 
                              
currentReading.getLastReadingForThisMote().getParentMoteID() ) {
                              currentMote.setParentMote( parentMote );
                              break;
                           }
                        }
                     }
                     else {
                        currentMote.setParentMote( null );
                     }
                     moteStateRestored.set( currentMote.getMoteID() );

                     /**
                     * We have to manually keep track of this number because
                     * JDK 1.3 does not support cardinality() method for the
                     * BitSet object. If it did (as in JDK 1.4), we would just
                     * check that the cardinality of the BitSet object was the
                     * same as the number of motes.
                     * */
                     numberOfMotesRestored++;
                     break;
                  }
               }
            }
         }
      }
      // Play them back slowly
      long sleepTime = 0;
      for( int readingsCtr = playbackStartCtr; readingsCtr < readingsCollected 
&& continueRun;
           readingsCtr++ ) {
         /**
          * Iterate through the remaining readings in the cloned vector. If it 
is
          * a Mote reading, find the appropriate mote and apply it. If it is a 
target
          * property, add it to the Vector of readings used for display. Don't 
forget
          * to sleep for the appropriate amount of time before applying the next 
reading.
          * */
         Object currentObject = copyVctReadingClone.elementAt( readingsCtr );
         if( currentObject.getClass().getName().equals( MoteReading.ClassName ) 
) {
            MoteReading currentMoteReading = (MoteReading) currentObject;
            sleepTime = currentMoteReading.getTimestamp() - lastReadingTime;
            if( sleepTime > 0 ) {
               try {
                  Thread.sleep( sleepTime );
               } catch( InterruptedException ie ) {
                  ie.printStackTrace();
               }
            }
            lastReadingTime = currentMoteReading.getTimestamp();
            gpanel.surf.vctReadingClone.add( currentMoteReading );
            ListIterator motesIter = gpanel.surf.vctMotesClone.listIterator();
            Mote currentMote = null;
            while( motesIter.hasNext() ) {
               currentMote = (Mote)motesIter.next();
               if( currentMote.getMoteID() == currentMoteReading.getMoteID() ) {
                  currentMote.setLastReading( currentMoteReading );
                  if( currentMoteReading.getParentMoteID() > 0 ) {
                     ListIterator parentMotesIter = 
gpanel.surf.vctMotesClone.listIterator();
                     Mote parentMote = null;
                     currentMote.setParentMote( null );
                     while( parentMotesIter.hasNext() ) {
                        parentMote = (Mote)parentMotesIter.next();
                        if( parentMote.getMoteID() == 
currentMoteReading.getParentMoteID() ) {
                           currentMote.setParentMote( parentMote );
                           break;
                        }
                     }
                  }
                  else {
                     currentMote.setParentMote( null );
                  }
                  break;
               }
            }
         }
         else if( currentObject.getClass().getName().equals( 
TargetProperty.ClassName ) ) {
            TargetProperty currentProperty = (TargetProperty) currentObject;
            sleepTime = currentProperty.getTimestamp() - lastReadingTime;
            if( sleepTime > 0 ) {
               try {
                  Thread.sleep( sleepTime );
               } catch( InterruptedException ie ) {
                  ie.printStackTrace();
               }
            }
            lastReadingTime = currentProperty.getTimestamp();
            gpanel.surf.vctReadingClone.add( currentProperty );
         }
         else {
            MIRProperty currentProperty = (MIRProperty) currentObject;
            sleepTime = currentProperty.getTimestamp() - lastReadingTime;
            if( sleepTime > 0 ) {
               try {
                  Thread.sleep( sleepTime );
               } catch( InterruptedException ie ) {
                  ie.printStackTrace();
               }
            }
            lastReadingTime = currentProperty.getTimestamp();
            gpanel.surf.vctReadingClone.add( currentProperty );
            if( currentProperty.getMIRType() == MIRProperty.START ) {
               gpanel.surf.displayMIRClone.set( currentProperty.getID() );
            }
            else {
               gpanel.surf.displayMIRClone.clear( currentProperty.getID() );
            }
         }
      }
      gpanel.surf.vctReadingClone.clear();
      gpanel.surf.vctReadingClone.addAll( (Collection)copyVctReadingClone );
      gpanel.surf.vctMotesClone = (Vector)copyVctMotesClone.clone();
      for( int i = 0; i < copyVctMotesClone.size(); i++ ) {
         Mote thisMote = (Mote)copyVctMotesClone.get( i );
         gpanel.surf.vctMotesClone.set( i, thisMote.clone() );
      }
      gpanel.surf.displayMIRClone = (BitSet)copyDisplayMIRClone.clone();
      System.gc();
   }

   public void halt() {
      continueRun = false;
   }
}
