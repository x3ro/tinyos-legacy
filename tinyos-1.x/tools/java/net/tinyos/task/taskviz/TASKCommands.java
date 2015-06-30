/*
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
package net.tinyos.task.taskviz;

import java.awt.*;
import java.awt.image.*;
import java.awt.event.*;
import javax.swing.border.*;
import java.awt.geom.*;
import javax.swing.*;
import javax.swing.event.*;
import java.util.*;
import java.io.File;
import java.io.IOException;

import net.tinyos.task.taskapi.*;

/**
 */
public class TASKCommands implements ListSelectionListener { 

  public String TAB2TIP = "Use to send commands to the network";

  public String BUTTON7 = "Execute Command";
  public JList  list3;

  public JButton button7;  
  public JComboBox jcombo1;
  JTextField commandParam;
  Vector commands = new Vector();
  Vector moteInfos = new Vector();
  Configuration config;
  private JFrame parentFrame;
  private JPanel parentPanel;
  TASKClient client;

  public TASKCommands(JFrame parentFrame, TASKClient client, JPanel parentPanel) {
    commands = client.getCommands();
    this.parentFrame = parentFrame;
    this.parentPanel = parentPanel;
    this.client = client;
  }

  public void preparePanel(String cName) {
    parentPanel.removeAll();
    moteInfos = client.getAllMoteClientInfo(cName);
     // utility classes
    Border b = BorderFactory.createBevelBorder(BevelBorder.LOWERED);
    parentPanel.setBorder(b);

    ///////////////
    // tab2 
    parentPanel.setLayout(new BorderLayout());

    Vector com = new Vector();
    for (int i=0; i<commands.size(); i++) {
      TASKCommandInfo ci = (TASKCommandInfo)commands.elementAt(i);
      if (ci.getNumArgs() > 0) {
        System.out.println(ci.getCommandName()+", "+ci.getArgType(0)+", "+ci.getNumArgs()+", "+ci.getDescription());
      }
      else {
        System.out.println(ci.getCommandName()+", "+ci.getNumArgs()+", "+ci.getDescription());
      }
      com.addElement(ci.getCommandName());
    }

    JPanel column = new JPanel();
    BoxLayout bl = new BoxLayout(column, BoxLayout.Y_AXIS);
    column.setLayout(bl);
    list3 = new JList(com);
    JScrollPane scrollPane = new JScrollPane(list3);
    column.add(scrollPane);

    list3.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
    list3.addListSelectionListener(this);

    commandParam = new JTextField(30);
    column.add(commandParam);
    button7 = new JButton(BUTTON7);
    column.add(button7);

    button7.addActionListener(new ActionListener() {
      public void actionPerformed(ActionEvent ae) {
        int command = list3.getSelectedIndex();
        if (command < 0) {
          JOptionPane.showMessageDialog(parentFrame, "No command selected", "Error", JOptionPane.ERROR_MESSAGE);
          return;
        }
        else {
          if (commandParam.getText().equals("N/A")) {
            TASKCommand gskc = null;
            String it = (String)jcombo1.getSelectedItem();
            if (it.equals("All Motes")) {
              gskc = new TASKCommand((String)list3.getSelectedValue(), new Vector(), TASKCommand.BROADCAST_ID);
            }
            else {
              gskc = new TASKCommand((String)list3.getSelectedValue(), new Vector(), Short.parseShort(it));
            }
            int x = client.submitCommand(gskc);
            System.out.println(x);
          }
          else {
            int p;
            try {
              p = Integer.parseInt(commandParam.getText());
            } catch (NumberFormatException nfe) {
                JOptionPane.showMessageDialog(parentFrame, "Command parameter must be of type integer", "Error", JOptionPane.ERROR_MESSAGE);
                return;
            }
            TASKCommand gskc = null;
            String it = (String)jcombo1.getSelectedItem();
            if (it.equals("All Motes")) {
              gskc = new TASKCommand((String)list3.getSelectedValue(), new Vector(), TASKCommand.BROADCAST_ID);
            }
            else {
              gskc = new TASKCommand((String)list3.getSelectedValue(), new Vector(), Short.parseShort(it));
            }
            int x = client.submitCommand(gskc);
            System.out.println(x);
        
            // send command
          }
        }
        // ANIND: RUN COMMAND HERE
      }
    });
    
    Vector ms = new Vector();
    ms.addElement("All Motes");
    for (int i=0; i<moteInfos.size(); i++) {
      int id = ((TASKMoteClientInfo)moteInfos.elementAt(i)).moteId;
      ms.addElement(String.valueOf(id));
    }
    jcombo1 = new JComboBox(ms);
    JPanel panel5 = new JPanel();
    panel5.setLayout(new BorderLayout());
    panel5.add(jcombo1, BorderLayout.NORTH);
    
    parentPanel.add(column, BorderLayout.CENTER);
    parentPanel.add(panel5, BorderLayout.EAST);
  }

  public void valueChanged(ListSelectionEvent e) {
    if (e.getValueIsAdjusting()) {
      return;
    }
    JList list = (JList)e.getSource();
    if (list.isSelectionEmpty()) {
      commandParam.setEnabled(false);
      commandParam.setText("N/A");
    }
    else {
      int index = list.getSelectedIndex();
      TASKCommandInfo ci = (TASKCommandInfo)commands.elementAt(index);
      if (ci.getNumArgs() == 1) {
        commandParam.setEnabled(true);
        commandParam.setText("Enter parameter");
      }
      else {
        commandParam.setEnabled(false);
        commandParam.setText("N/A");
      }
    }
  }
}
