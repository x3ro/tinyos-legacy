/** * Copyright (c) 2003 - The Ohio State University. * All rights reserved. * * Permission to use, copy, modify, and distribute this software and its * documentation for any purpose, without fee, and without written agreement is * hereby granted, provided that the above copyright notice, the following * two paragraphs, and the author attribution appear in all copies of this * software. * * IN NO EVENT SHALL THE OHIO STATE UNIVERSITY BE LIABLE TO ANY PARTY FOR * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE OHIO STATE * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. * * THE OHIO STATE UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES, * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS * ON AN "AS IS" BASIS, AND THE OHIO STATE UNIVERSITY HAS NO OBLIGATION TO * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS. */

/*
* FILE NAME
*
*     DisplayPanel.java
*
* DESCRIPTION
*
*   This panel is used to display text area that contains output message
* generated and received from the mote.  It is generic enough to be used 
* with socket or COM Port so long as the program implements socket or 
* COM Port (program that listens to them) calls the method defined in this
* class.  It is used mainly for debugging purpose which helps explain the
* behavior on the graphic panel.  This panel is converted to internal frame 
* so that it can be hidden from the real demo but keep its functionality.
*
* Author : Mark E. Miyashita  - Kent State University
*
* Modification History
*
* 4/20/2003 Mark E. Miyashita - Removed out dated methods from this class
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

public class DisplayPanel extends JInternalFrame implements Runnable {
 
   protected JTextArea textarea;
   protected String newline ="\n";
   private JScrollPane scrollList;
   private Thread thread;
   JCheckBox windowResizable   = null;
   JCheckBox windowClosable    = null;
   JCheckBox windowIconifiable = null;
   JCheckBox windowMaximizable = null;

   public DisplayPanel() {  /* Constructor */
      super();

      /* Setup Internal Frame options */
      windowResizable   = new JCheckBox("Window Resize", true);
      windowIconifiable = new JCheckBox("Window iconfy", true);
      windowMaximizable = new JCheckBox("Window Maximize", true);
     
      setTitle("Message Display");
      setMaximizable(windowMaximizable.isSelected());
      setIconifiable(windowIconifiable.isSelected());
      setResizable(windowResizable.isSelected());
 
      getContentPane().setLayout(new BorderLayout());

      /* Setup Layout for this panel */
      setPreferredSize(new Dimension(300,300));

      /* Set border around panel and display title */
      setBorder(new EtchedBorder());

      /* Add text area for Mote message display */
      textarea = new JTextArea(30,30);
      textarea.setEditable(false);      /* Display Only */

      /* Add this text area to ScrollPane so that user can scroll
      * through the mesage that gets displayed on the screen 
      */
      scrollList = new JScrollPane(textarea);
      scrollList.setPreferredSize(new Dimension(300, 300));

      /* Set size and make it visible */
      setSize(getPreferredSize());      

      getContentPane().add(scrollList);

      show();      

   }

   public Dimension getMinimumSize() {
      return getPreferredSize();
   }
    
   public Dimension getPreferredSize() {
      return new Dimension(300,300);
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

   public synchronized void clear() {  /* Erase everything on text area */
      textarea.setText("");
   }

   /* Method used to write the simple Mote message on the text area */
   protected synchronized void displayMsg(String msg) {
      textarea.append(msg);  /* Display message on the panel */
   }
}
