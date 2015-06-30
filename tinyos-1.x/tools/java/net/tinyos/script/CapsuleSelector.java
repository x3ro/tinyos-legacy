// $Id: CapsuleSelector.java,v 1.3 2004/10/21 22:26:33 selfreference Exp $

/*									tab:4
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
/* Authors:	Phil Levis <pal@cs.berkeley.edu>
 * Date:        Aug 21 2002
 * Desc:        Capsule type selector for CapsuleInjector.
 *
 */

/**
 * @author Phil Levis <pal@cs.berkeley.edu>
 */


package net.tinyos.script;

import java.awt.*;
import java.awt.event.*;
import java.io.*;
import java.net.*;
import java.util.*;
import javax.swing.*;
import javax.swing.event.*;

import net.tinyos.message.*;
import net.tinyos.util.*;



public class CapsuleSelector extends JPanel {
  private ButtonGroup group;
  private ConstantMapper map;
  private Vector buttons;
  private ScripterWindowed scripter;
  
  public CapsuleSelector(ConstantMapper capsuleMap, ScripterWindowed scripter) {
    this.setFont(TinyLook.defaultFont());
    this.setLayout(new BoxLayout(this, BoxLayout.Y_AXIS));
    this.map = capsuleMap;
    this.scripter = scripter;
    
    //System.err.println("Creating capsule selector.");
    buttons = new Vector();
    group = new ButtonGroup();
    Enumeration names = map.names();
    while (names.hasMoreElements()) {
      String name = (String)names.nextElement();
      //System.err.println("Creating button " + name);
      if (!name.equals("NUM") &&
	  !name.equals("SIZE") &&
	  !name.equals("INVALID")) {
	prepareButton(name, map.nameToCode(name));
      }
    }
    sortButtons();
    addButtons();
    this.setAlignmentX(LEFT_ALIGNMENT);
  }

  private void prepareButton(String name, byte code) {
    String text = name.replace('_', ' ');
    text = text.toLowerCase();
    text = text.substring(0,1).toUpperCase() + text.substring(1);
    CapsuleButton button = new CapsuleButton(text, name, code);
    buttons.add(button);
    button.setFont(TinyLook.defaultFont());
  }

  private void addButtons() {
    Enumeration btns = buttons.elements();
    while (btns.hasMoreElements()) {
      CapsuleButton button = (CapsuleButton)btns.nextElement();
      button.addChangeListener(new CapsuleChangeListener(button, scripter));
      group.add(button);
      add(button);
    }
  }
    
  private void sortButtons() {
    int size = buttons.size();
    for (int i = 0; i < size; i++) {
      CapsuleButton b = (CapsuleButton)buttons.elementAt(i);
      for (int j = i+1; j < size; j++) {
	CapsuleButton t = (CapsuleButton)buttons.elementAt(j);
	if (t.getText().compareTo(b.getText()) < 0) {
	  buttons.remove(t);
	  buttons.insertElementAt(t, i);
	  b = t;
	}
      }
    }
	
    CapsuleButton first = (CapsuleButton)buttons.firstElement();
    first.doClick();
  }
    
  private class CapsuleButton extends JRadioButton {
    private String text;
    private String name;
    private byte code;

    public CapsuleButton(String text, String name, byte code) {
      super(text);
      this.text = text;
      this.name = name;
      this.code = code;
    }

    public byte getCode() {return code;}
    public String getText() {return text;}
    public String getName() {return name;}
  }

  private class CapsuleChangeListener implements ChangeListener {
    private CapsuleButton button;
    private ScripterWindowed scripter;
    
    public CapsuleChangeListener(CapsuleButton b, ScripterWindowed s) {
      button = b;
      scripter = s;
    }

    public void stateChanged(ChangeEvent e) {
      if (button.isSelected()) {
	scripter.changeToCapsule(button.getText());
      }
    }
  }
  
  public byte getType() {
    Enumeration btns = buttons.elements();
    while (btns.hasMoreElements()) {
      CapsuleButton b = (CapsuleButton)btns.nextElement();
      if (b.isSelected()) {
	return b.getCode();
      }
    }
    return (byte)-1;
  }

  public String getSelected() {
    Enumeration btns = buttons.elements();
    while (btns.hasMoreElements()) {
      CapsuleButton b = (CapsuleButton)btns.nextElement();
      if (b.isSelected()) {
	return b.getText();
      }
    }
    return "unknown";
  }

  public static void main(String[] args) {
    try {
      String arg = "net.tinyos.vm_asm.MateConstants";
      if (args.length > 1) {
	arg = args[1];
      }
      ConstantMapper codes = new ConstantMapper(arg, args[0]);
      Enumeration names = codes.names();
      while (names.hasMoreElements()) {
	String name = (String)names.nextElement();
      }
      JFrame frame = new JFrame();
      CapsuleSelector s = new CapsuleSelector(codes, null);
      frame.getContentPane().add(s);
      frame.pack();
      frame.setVisible(true);
    }
    catch (Exception ex) {
      ex.printStackTrace();
    }
  }
}
