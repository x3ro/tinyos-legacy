/** * Copyright (c) 2003 - The Ohio State University. * All rights reserved. * * Permission to use, copy, modify, and distribute this software and its * documentation for any purpose, without fee, and without written agreement is * hereby granted, provided that the above copyright notice, the following * two paragraphs, and the author attribution appear in all copies of this * software. * * IN NO EVENT SHALL THE OHIO STATE UNIVERSITY BE LIABLE TO ANY PARTY FOR * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE OHIO STATE * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. * * THE OHIO STATE UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES, * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS * ON AN "AS IS" BASIS, AND THE OHIO STATE UNIVERSITY HAS NO OBLIGATION TO * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS. */

import java.awt.*;
import java.awt.event.*;
import javax.swing.*;
import javax.swing.event.*;
import javax.swing.border.*;
import java.io.*;
import java.util.*;
import java.lang.*;

public class PlaybackPanel extends JPanel implements ActionListener {
   private static Label playbackText = new Label( "Playback the last" );
   private static Label playbackUnit = new Label( "seconds" );
   private static JTextField playbackTimeTextField;
   private static JButton playbackStartButton;
   private GraphicsPanel gpanel;
   private ButtonPanel bpanel;
   private PlaybackThread pbthread;
   private static int defaultPlaybackTime = 15;
   
   public PlaybackPanel( GraphicsPanel g, ButtonPanel b ) {
      gpanel = g;
      bpanel = b;
      playbackTimeTextField = new JTextField( Integer.toString( 
defaultPlaybackTime ), 4 );
      playbackStartButton = new JButton( "Go" );
      playbackStartButton.setVerticalTextPosition(AbstractButton.CENTER);
      playbackStartButton.setHorizontalTextPosition(AbstractButton.LEFT);
      playbackStartButton.setMnemonic('l');
      playbackStartButton.setActionCommand("Go");
      playbackStartButton.addActionListener( this );
      this.setSize( this.getPreferredSize() );
      pbthread = null;


      add( playbackText );
      add( playbackTimeTextField );
      add( playbackUnit );
      add( playbackStartButton );
   }
   public void actionPerformed( ActionEvent e ) {
      /**
       * Create a playback thread and start it
       * */
      int playbackTime;
      bpanel.hidePlaybackFrame();
      // bpanel.disablePlayback();
      bpanel.disableFreeze();
      try {
         String textValue = playbackTimeTextField.getText();
         playbackTime = Integer.parseInt( textValue );
      } catch( NullPointerException npe ) {
         playbackTime = defaultPlaybackTime;
      } catch( NumberFormatException nfe ) {
         playbackTime = defaultPlaybackTime;
      } catch( Exception ex ) {
         playbackTime = defaultPlaybackTime;
      }
      gpanel.surf.setPlaybackTime( playbackTime );
      pbthread = new PlaybackThread( gpanel, bpanel );
      pbthread.start();
      pbthread.stop();
      /*
      bpanel.enablePlayback();
      bpanel.enableFreeze();
      */
   }
   public PlaybackThread getPlaybackThread() {
      return pbthread;
   }
}
