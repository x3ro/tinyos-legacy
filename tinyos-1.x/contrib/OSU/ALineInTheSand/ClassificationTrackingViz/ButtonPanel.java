/** * Copyright (c) 2003 - The Ohio State University. * All rights reserved. * * Permission to use, copy, modify, and distribute this software and its * documentation for any purpose, without fee, and without written agreement is * hereby granted, provided that the above copyright notice, the following * two paragraphs, and the author attribution appear in all copies of this * software. * * IN NO EVENT SHALL THE OHIO STATE UNIVERSITY BE LIABLE TO ANY PARTY FOR * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE OHIO STATE * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. * * THE OHIO STATE UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES, * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS * ON AN "AS IS" BASIS, AND THE OHIO STATE UNIVERSITY HAS NO OBLIGATION TO * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS. */

/*
* FILE NAME
*
*     ButtonPanel.java
*
* DESCRIPTION
*
* This panel is the central location where simulation is controled.  For
* instance, you can start, stop, and clear the simulation.
*
* Author :  Mark E. Miyashita  -  Kent State Univerisity,
*           Adnan Vora - Kent State University (avora@mcs.kent.edu)
*
* Modification history
* 
* 4/19/2003 Mark E. Miyashita - removed all old methods and variables not 
related to
*                               current implementation.  Replaced socket-Comm 
Port manager
*                               with call to JMX objects
* 4/22/2003 Mark E. Miyashita - Added call to CopyBaseStation in the 
GraphicsPanel
* 4/25/2003 Adnan Vora        - Added Playback/Freeze/Unfreeze
* 4/26/2003 Adnan Vora        - Added documentation
* 4/28/2003 Mark E. Miyashita - Rewrite of this file to use JToolBar instead of 
JPanel
* 6/06/2003 Adnan Vora         - Removed the "Topology" button (moved it to the 
MenuBar)
*
*/

/* Import required Java class files */

import java.awt.*;
import java.awt.event.*;
import javax.swing.*;
import javax.swing.event.*;
import javax.swing.border.*;
import java.io.*;
import java.util.*;
import java.lang.*;

public class ButtonPanel extends JToolBar {

   private static JButton clearButton;          /* Clear button */
   private static JButton startButton;          /* Start button */
   private static JButton stopButton;           /* Stop button */
   // private static JButton showTopologyButton;   /* Show Topology button */
   private static JButton freezeButton;         /* Freeze/Unfreeze button */
   private static JButton playbackButton;       /* Playback button */
   private GraphicsPanel gpanel;                /* Graphics panel with Topology 
*/
   private DisplayPanel dpanel;                 /* Display panel with message 
displayed in text area */
   private AggregatePanel apanel;               /* Display panel with summary 
information */
   ButtonGroup   bttnGroup = new ButtonGroup(); /* Group componets used in this 
panel */
   private Vector vctMotes  = new Vector();     /* Vector of Motes */
   private Field vFieldSize;                    /* Field size of simulation */
   private BaseStationMote vBaseStationMote;    /* Base Station mote information 
*/
   protected String newline ="\n";              /* constant denoting new line */
   private static MoteCommunicationAgent agent = null;
   private ButtonPanel bpanel;
   private JFrame playbackFrame;
   private PlaybackPanel pPanel;
   
   /* Constructor for ButtonPanel */

   public ButtonPanel(DisplayPanel dpanel, GraphicsPanel gpanel, AggregatePanel 
apanel) {

      this.gpanel = gpanel;
      this.dpanel = dpanel;
      this.apanel = apanel;
      this.bpanel = this;

      /* Initialize internal structure */
      CreateToolBar();

      playbackFrame = new JFrame( "Playback" );
      pPanel = new PlaybackPanel( gpanel, bpanel );
      playbackFrame.setContentPane( pPanel );

   }

   private void CreateToolBar() {

      /* Create buttons */

      clearButton = new JButton("Clear");
      startButton = new JButton("Start");
      stopButton = new JButton("Stop");
      // showTopologyButton = new JButton( "Topology" );
      freezeButton = new JButton( "Freeze" );
      playbackButton = new JButton( "Playback" );

      /* Set properties for start button */
      startButton.setVerticalTextPosition(AbstractButton.CENTER);
      startButton.setHorizontalTextPosition(AbstractButton.LEFT);
      startButton.setMnemonic('s');
      startButton.setActionCommand("Start");
      startButton.addActionListener(new StartListener());
      startButton.setToolTipText("Click this button to Start Simulation.");

      /* Set properties for stop button */
      stopButton.setVerticalTextPosition(AbstractButton.CENTER);
      stopButton.setHorizontalTextPosition(AbstractButton.LEFT);
      stopButton.setMnemonic('t');
      stopButton.setActionCommand("Stop");
      stopButton.addActionListener(new StopListener());
      stopButton.setToolTipText("Click this button to Stop Simulation.");
      stopButton.setEnabled(false);

      /* Set properties for clear button */
      clearButton.setVerticalTextPosition(AbstractButton.CENTER);
      clearButton.setHorizontalTextPosition(AbstractButton.LEFT);
      clearButton.setMnemonic('c');
      clearButton.setActionCommand("Clear");
      clearButton.addActionListener(new ClearListener());
      clearButton.setToolTipText("Click this button to clear display.");

      /* Set properties for show topology button */
      /*
      showTopologyButton.setVerticalTextPosition(AbstractButton.CENTER);
      showTopologyButton.setHorizontalTextPosition(AbstractButton.LEFT);
      showTopologyButton.setMnemonic('t');
      showTopologyButton.setActionCommand("Topology");
      showTopologyButton.addActionListener(new TopologyListener());
      showTopologyButton.setToolTipText("Click this button to display 
topology");
      */

      /* Set properties for freeze button */
      freezeButton.setVerticalTextPosition(AbstractButton.CENTER);
      freezeButton.setHorizontalTextPosition(AbstractButton.LEFT);
      freezeButton.setMnemonic('f');
      freezeButton.setActionCommand("Freeze");
      freezeButton.addActionListener(new FreezeListener());
      freezeButton.setToolTipText("Click this button to freeze/unfreeze" );
      freezeButton.setEnabled(false);

      /* Set properties for playback button */
      playbackButton.setVerticalTextPosition(AbstractButton.CENTER);
      playbackButton.setHorizontalTextPosition(AbstractButton.LEFT);
      playbackButton.setMnemonic('p');
      playbackButton.setActionCommand("Playback");
      playbackButton.addActionListener(new PlaybackListener());
      playbackButton.setToolTipText("Click this button to Playback");
      playbackButton.setEnabled(false);

      add(Box.createRigidArea(new Dimension(10,1)));
      add(clearButton);
      add(Box.createRigidArea(new Dimension(1,10)));
      add(startButton);
      add(Box.createRigidArea(new Dimension(1,10)));
      add(stopButton);
      // add(Box.createRigidArea(new Dimension(1,10)));
      // add(showTopologyButton);
      add(Box.createRigidArea(new Dimension(1,10)));
      add(freezeButton);
      add(Box.createRigidArea(new Dimension(1,10)));
      add(playbackButton);
   }

   /* Handle event when show topology button gets pressed */

   /*
   protected class TopologyListener implements ActionListener {
      public TopologyListener() {}
   
      public void actionPerformed(ActionEvent e) {
         gpanel.surf.setShowTopology( !gpanel.surf.isShowTopology() );
      }
   }
   */

   public void enablePlayback() {
      playbackButton.setText( "Playback" );
      playbackButton.setEnabled( true );
   }
   public void enableFreeze() {
      freezeButton.setEnabled( true );
   }
   public void disablePlayback() {
      playbackButton.setEnabled( false );
   }
   public void disableFreeze() {
      freezeButton.setEnabled( false );
   }

   /* Handle event when clear button gets pressed */

   protected class ClearListener implements ActionListener {
      public ClearListener() {}

      public void actionPerformed(ActionEvent e) {
         dpanel.clear();   /* Clear text area which displays Mote output */
         apanel.clear();
      }
   }

   /* Handle event when Stop button gets pressed */

   protected class StopListener implements ActionListener {
      public StopListener() {}

      public void actionPerformed(ActionEvent e) {   /* Stop Simulation */
         if ( agent != null ) {
            dpanel.displayMsg("Simulation stopped" + newline );
            gpanel.surf.stop();                /* Stop all threads */
            dpanel.stop();                     /* Stop display panel */
            apanel.clear();
            apanel.stop();
            agent.ClearMoteLocation();         /* Clear vector of mote locations 
*/
            agent.StopMoteMessageListener();   /* Stop MoteMessage MBean thread 
*/
            agent = null;
            vctMotes.removeAllElements();      /* Remove all motes information 
*/
            stopButton.setEnabled(false);      /* Disable stop button */
            startButton.setEnabled(true);      /* Enable start button */
         }
      }
   }

   /* Handle event when Start button gets pressed */

   protected class StartListener implements ActionListener {
      public StartListener() {}
   
      public void actionPerformed(ActionEvent e) {  /* Start Simulation */
         if ( agent == null ) {     
            stopButton.setEnabled(true);       /* Enable stop button */
            startButton.setEnabled(false);     /* Disable start button */
            dpanel.start();                    /* Start Display Panel thread */
            dpanel.displayMsg("Start Simulation" + newline );
            agent = new MoteCommunicationAgent(dpanel, gpanel);
            vFieldSize = agent.getFieldSize(); /* Obtain Field Size for this 
simulation */
            vBaseStationMote = agent.getBaseStation(); /* Get Base station 
information */
            vctMotes = agent.getMoteLocation();/* Obtain mote locations for this 
simulation */
            gpanel.surf.start();               /* Start Graphics Panel thread */
            gpanel.surf.CopyFieldSize(vFieldSize);/* Copy field size information 
*/
            gpanel.surf.CopyBaseStation(vBaseStationMote);/* Copy Base Station 
information */
            gpanel.surf.CopyMoteInfo(vctMotes);/* Copy vector of mote 
information to graphic panel */
            apanel.start();
            agent.StartMoteMessageListener(); 
            freezeButton.setEnabled( true );
            playbackButton.setEnabled( false );
         }
      }
   }

   /* Handle event when freeze button gets pressed */

   protected class FreezeListener implements ActionListener {
      public FreezeListener() {}

      public void actionPerformed(ActionEvent e) {  /* Start Simulation */
         /**
          * This line tells the graphics panel that we are now in
          * freeze mode or that we just got out of freeze mode
          *
          * Note that playback is enabled only in freeze mode
          * */
         gpanel.surf.setFreeze( !gpanel.surf.isFreeze() );
         if( gpanel.surf.isFreeze() ) {
            freezeButton.setText( "Unfreeze" );
            playbackButton.setEnabled( true );
         }
         else {
            freezeButton.setText( "Freeze" );
            playbackButton.setEnabled( false );
         }
      }
   }

   /* Handle event when playback button gets pressed */
   protected class PlaybackListener implements ActionListener {
      public PlaybackListener() {}

      public void actionPerformed(ActionEvent e) {  /* Start Simulation */
         if( playbackButton.getText().equals( "Playback" ) ) {
            playbackButton.setText( "Stop Playback" );
            freezeButton.setEnabled( false );
            playbackFrame.pack();
            playbackFrame.show();
         }
         else {
            playbackButton.setText( "Playback" );
            PlaybackThread playbackThread = pPanel.getPlaybackThread();
            playbackThread.halt();
				gpanel.surf.setPlaybackStartTime( 0 );
            freezeButton.setEnabled( true );
         }
      }
   }

   public void hidePlaybackFrame() {
      playbackFrame.hide();
   }
} 

