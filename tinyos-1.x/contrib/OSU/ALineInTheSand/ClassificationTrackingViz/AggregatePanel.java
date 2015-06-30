/** * Copyright (c) 2003 - The Ohio State University. * All rights reserved. * * Permission to use, copy, modify, and distribute this software and its * documentation for any purpose, without fee, and without written agreement is * hereby granted, provided that the above copyright notice, the following * two paragraphs, and the author attribution appear in all copies of this * software. * * IN NO EVENT SHALL THE OHIO STATE UNIVERSITY BE LIABLE TO ANY PARTY FOR * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE OHIO STATE * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. * * THE OHIO STATE UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES, * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS * ON AN "AS IS" BASIS, AND THE OHIO STATE UNIVERSITY HAS NO OBLIGATION TO * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS. */

/*
* FILE NAME
*
*     AggregatePanel.java
*
* DESCRIPTION
*
*   This panel is used to display aggregate (summary) information of the
* field.
*
* Author : Adnan Vora  - Kent State University (avora@mcs.kent.edu)
*
* Modification History
*
*/

/* Import require Java class files */

import java.awt.*;
import java.io.*;
import java.util.*;
import java.net.*;
import javax.swing.*;
import javax.swing.event.*;
import javax.swing.border.*;
import java.beans.*;

public class AggregatePanel extends JInternalFrame implements Runnable {
   private Vector vctMotesClone = null;
   private Vector vctReadingsClone = null;
   protected JLabel lblTargetNumber;
   protected JLabel lblLiveMotes;
   protected JLabel lblAvgPower;
   protected JTextField txtTargetNumber;
   protected JTextField txtLiveMotes;
   protected JTextField txtAvgPower;
   private Thread thread;
   JCheckBox windowResizable   = null;
   JCheckBox windowClosable    = null;
   JCheckBox windowIconifiable = null;
   JCheckBox windowMaximizable = null;

   public AggregatePanel() {  /* Constructor */
       super();

      /* Setup Internal Frame options */
      windowResizable   = new JCheckBox("Window Resize", false);
      windowIconifiable = new JCheckBox("Window iconfy", true);
      windowMaximizable = new JCheckBox("Window Maximize", false);
      
      setTitle("Summary Display");
      setMaximizable(windowMaximizable.isSelected());
      setIconifiable(windowIconifiable.isSelected());
      setResizable(windowResizable.isSelected());
      setBackground( Color.lightGray );

      GridBagLayout gridBag = new GridBagLayout();
      GridBagConstraints gridBagCon = new GridBagConstraints();

      /* Setup Layout for this panel */
      getContentPane().setLayout( gridBag );
      setPreferredSize(new Dimension(350,150));

      /* Set border around panel and display title */
      setBorder(new EtchedBorder());

      /**
       * Add text fields and labels 
       * */
      gridBagCon.gridwidth = GridBagConstraints.RELATIVE;
      gridBagCon.anchor = GridBagConstraints.EAST;
      lblTargetNumber = new JLabel( new String( "# of Targets  " ), SwingConstants.RIGHT );
      lblTargetNumber.setBackground( Color.lightGray );
      lblTargetNumber.setForeground( Color.black );
      gridBag.setConstraints( lblTargetNumber, gridBagCon );
      getContentPane().add( lblTargetNumber );

      gridBagCon.gridwidth = GridBagConstraints.REMAINDER;
      gridBagCon.anchor = GridBagConstraints.WEST;
      txtTargetNumber = new JTextField( 15 );
      txtTargetNumber.setBackground( Color.lightGray );
      txtTargetNumber.setForeground( Color.black );
      txtTargetNumber.setBorder( new EtchedBorder() );
      gridBag.setConstraints( txtTargetNumber, gridBagCon );
      getContentPane().add( txtTargetNumber );

      gridBagCon.gridwidth = GridBagConstraints.RELATIVE;
      gridBagCon.anchor = GridBagConstraints.EAST;
      lblLiveMotes = new JLabel( new String( "# of Live Motes  " ), SwingConstants.RIGHT );
      lblLiveMotes.setBackground( Color.lightGray );
      lblLiveMotes.setForeground( Color.black );
      gridBag.setConstraints( lblLiveMotes, gridBagCon );
      getContentPane().add( lblLiveMotes );

      gridBagCon.gridwidth = GridBagConstraints.REMAINDER;
      gridBagCon.anchor = GridBagConstraints.WEST;
      txtLiveMotes = new JTextField( 15 );
      txtLiveMotes.setBackground( Color.lightGray );
      txtLiveMotes.setForeground( Color.black );
      txtLiveMotes.setBorder( new EtchedBorder() );
      gridBag.setConstraints( txtLiveMotes, gridBagCon );
      getContentPane().add( txtLiveMotes );

      gridBagCon.gridwidth = GridBagConstraints.RELATIVE;
      gridBagCon.anchor = GridBagConstraints.EAST;
      lblAvgPower = new JLabel( new String( "Average Power per Mote  " ), SwingConstants.RIGHT );
      lblAvgPower.setBackground( Color.lightGray );
      lblAvgPower.setForeground( Color.black );
      gridBag.setConstraints( lblAvgPower, gridBagCon );
      getContentPane().add( lblAvgPower );

      gridBagCon.gridwidth = GridBagConstraints.REMAINDER;
      gridBagCon.anchor = GridBagConstraints.WEST;
      txtAvgPower = new JTextField( 15 );
      txtAvgPower.setBackground( Color.lightGray );
      txtAvgPower.setForeground( Color.black );
      txtAvgPower.setBorder( new EtchedBorder() );
      gridBag.setConstraints( txtAvgPower, gridBagCon );
      getContentPane().add( txtAvgPower );

      txtTargetNumber.setEditable( false );
      txtLiveMotes.setEditable( false );
      txtAvgPower.setEditable( false );

      txtTargetNumber.setText( "" );
      txtLiveMotes.setText( "" );
      txtAvgPower.setText( "" );

      /* Set size and make it visible */
      setSize(getPreferredSize());      

      // Set this internal frame to be selected
      try {
         setSelected(true);
      } catch (java.beans.PropertyVetoException e2) {
      }
      show();      
   }

   public Dimension getMinimumSize() {
      return getPreferredSize();
   }
    
   public Dimension getPreferredSize() {
      return new Dimension(350,150);
   }

   public JInternalFrame getInternalFrame() {
      return this;
   }

   /* Start this panel as Thread */

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
      Thread me = Thread.currentThread();
   
      while (thread == me) {
         try {
            thread.sleep(100);
         } catch (InterruptedException e) {
            break;
         }
      }
   }

   public synchronized void clear() {  
      /**
       * Erase everything on text area 
       * */
      txtTargetNumber.setText( "" );
      txtLiveMotes.setText( "" );
      txtAvgPower.setText( "" );
   }

   /**
    * Method used to display summary properties on the
    * Aggregate Panel
    * */
   protected synchronized void displayMsg( Vector vctMotes, Vector vctReadings ) {
      int numTarg = 0;
      int numLive = 0;
      double numAvgPower = 0;

      /**
       * Clone the vectors passed to you so that there is no
       * concurrent use of these vectors
       * */
      if( vctMotes != null ) {
         vctMotesClone = (Vector)vctMotes.clone();
      }
      if( vctReadings != null ) {
         vctReadingsClone = (Vector)vctReadings.clone();
      }

      /**
       * Calculate average power per live mote
       * and the number of live motes only if the
       * motes vector that was passed is not null
       * */
      if( vctMotesClone != null && vctMotesClone.size() > 0 ) {
         ListIterator motesIter = vctMotesClone.listIterator();
         Mote currentMote = null;
         while( motesIter.hasNext() ) {
            currentMote = (Mote) motesIter.next();
            if( currentMote.isAlive() ) {
               numLive++;
               if( currentMote.getLastReading() != null ) {
                  numAvgPower += currentMote.getLastReading().getBatteryReading();
               }
            }
         }
         if( numLive > 0 ) {
            numAvgPower /= numLive;
         }
      }

      /**
       * Check for targets in the Readings vector if it was
       * not null
       * */
      if( vctReadingsClone != null && vctReadingsClone.size() > 0 ) {
         ListIterator readingsIter = vctReadingsClone.listIterator();
         Object currentObj = null;
         while( readingsIter.hasNext() ) {
             currentObj = readingsIter.next();
            if( currentObj.getClass().getName().equals( TargetProperty.ClassName ) ) {
               numTarg = 1;
               break;
            }
         }
      }
      /**
       * Copy the calculated properties to the text fields
       * */
      txtTargetNumber.setText( Integer.toString( numTarg ) );
      txtLiveMotes.setText( Integer.toString( numLive ) );
      txtAvgPower.setText( Double.toString( numAvgPower ) );

      /**
       * reset the vector clones to null
       * */
      if( vctMotesClone != null ) {
         vctMotesClone.removeAllElements();
         vctMotesClone = null;
      }
      if( vctReadingsClone != null ) {
         vctReadingsClone.removeAllElements();
         vctReadingsClone = null;
      }
   }
}
