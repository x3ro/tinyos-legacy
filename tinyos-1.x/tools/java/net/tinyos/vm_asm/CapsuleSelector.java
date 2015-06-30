// $Id: CapsuleSelector.java,v 1.6 2003/12/18 21:43:57 scipio Exp $

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


package net.tinyos.vm_asm;

import java.awt.*;
import java.awt.event.*;
import java.io.*;
import java.net.*;
import java.util.*;
import javax.swing.*;

import net.tinyos.message.*;
import net.tinyos.util.*;

public class CapsuleSelector extends JPanel {
    private ButtonGroup group;
    private JRadioButton sub0Button;
    private JRadioButton sub1Button;
    private JRadioButton sub2Button;
    private JRadioButton sub3Button;
    private JRadioButton clockButton;
    private JRadioButton sendButton;
    private JRadioButton receiveButton;
    private JRadioButton onceButton;
    
    public CapsuleSelector() {
	this.setFont(TinyLook.defaultFont());
	this.setLayout(new BoxLayout(this, BoxLayout.Y_AXIS));
	sub0Button = new JRadioButton("Subroutine 0");
	sub1Button = new JRadioButton("Subroutine 1");
	sub2Button = new JRadioButton("Subroutine 2");
      	sub3Button = new JRadioButton("Subroutine 3");
	clockButton = new JRadioButton("Clock");
	sendButton = new JRadioButton("Send");
	receiveButton = new JRadioButton("Receive");
	onceButton = new JRadioButton("Once");
	onceButton.doClick();

	clockButton.setFont(TinyLook.defaultFont());
	sendButton.setFont(TinyLook.defaultFont());
	receiveButton.setFont(TinyLook.defaultFont());
	onceButton.setFont(TinyLook.defaultFont());
	sub0Button.setFont(TinyLook.defaultFont());
	sub1Button.setFont(TinyLook.defaultFont());
	sub2Button.setFont(TinyLook.defaultFont());
	sub3Button.setFont(TinyLook.defaultFont());
	
	group = new ButtonGroup();
	group.add(clockButton);
	group.add(sendButton);
	group.add(receiveButton);
	group.add(onceButton);
	group.add(sub0Button);
	group.add(sub1Button);
	group.add(sub2Button);
	group.add(sub3Button);


	add(clockButton);
	add(sendButton);
	add(receiveButton);
	add(onceButton);
	add(sub0Button);
	add(sub1Button);
	add(sub2Button);
	add(sub3Button);

	this.setAlignmentX(LEFT_ALIGNMENT);
    }
    
    public short getType() {
	// These hardcoded numbers should be made non-hardcoded at some
	// point - pal
	if (sub0Button.isSelected()) {return (short)BombillaConstants.BOMB_CAPSULE_SUB0;}
	if (sub1Button.isSelected()) {return (short)BombillaConstants.BOMB_CAPSULE_SUB1;}
	if (sub2Button.isSelected()) {return (short)BombillaConstants.BOMB_CAPSULE_SUB2;}
	if (sub3Button.isSelected()) {return (short)BombillaConstants.BOMB_CAPSULE_SUB3;}
	if (clockButton.isSelected())   {return (short)BombillaConstants.BOMB_CAPSULE_CLOCK;}
	if (sendButton.isSelected())    {return (short)BombillaConstants.BOMB_CAPSULE_SEND;}
	if (receiveButton.isSelected()) {return (short)BombillaConstants.BOMB_CAPSULE_RECV;}
	if (onceButton.isSelected())    {return (short)BombillaConstants.BOMB_CAPSULE_ONCE;}
	return (short)-1;
    }
    
}
