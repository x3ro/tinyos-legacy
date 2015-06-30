// $Id: OptionSelector.java,v 1.3 2004/02/17 23:06:37 scipio Exp $

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
 * Desc:        Capsule options selector for CapsuleInjector.
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

import net.tinyos.message.*;
import net.tinyos.util.*;

public class OptionSelector extends JPanel {
    private ConstantMapper map;
    private Vector buttons;
     
    public OptionSelector(ConstantMapper optionMap) {
      this.setFont(TinyLook.defaultFont());
      this.setLayout(new BoxLayout(this, BoxLayout.Y_AXIS));
      this.map = optionMap;
      buttons = new Vector();
      Enumeration enum = map.names();
      while (enum.hasMoreElements()) {
	String name = (String)enum.nextElement();
	if (!name.equals("MASK")) {
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
      OptionButton button = new OptionButton(text, name, code);
      button.doClick();
      buttons.add(button);
      button.setFont(TinyLook.defaultFont());
    }

    private void addButtons() {
      Enumeration enum = buttons.elements();
      while (enum.hasMoreElements()) {
	OptionButton button = (OptionButton)enum.nextElement();
	add(button);
      }
    }

    private void sortButtons() {
      int size = buttons.size();
      for (int i = 0; i < size; i++) {
	OptionButton b = (OptionButton)buttons.elementAt(i);
	for (int j = i+1; j < size; j++) {
	  OptionButton t = (OptionButton)buttons.elementAt(j);
	  if (t.getText().compareTo(b.getText()) < 0) {
	    buttons.remove(t);
	    buttons.insertElementAt(t, i);
	    b = t;
	  }
	}
      }
    }

    public byte getOptions() {
	byte val = 0;
	Enumeration enum = buttons.elements();
	while (enum.hasMoreElements()) {
	    OptionButton b = (OptionButton)enum.nextElement();
	    if (b.isSelected()) {
		val |= b.getCode();
	    }
	}
	return val;
    }

    private class OptionButton extends JRadioButton {
	private String text;
	private String name;
	private byte code;

	public OptionButton(String text, String name, byte code) {
	    super(text);
	    this.text = text;
	    this.name = name;
	    this.code = code;
	}

	public byte getCode() {return code;}
	public String getText() {return text;}
	public String getName() {return name;}
    }

    
}
