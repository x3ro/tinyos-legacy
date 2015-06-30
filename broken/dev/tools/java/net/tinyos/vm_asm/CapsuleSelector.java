/*									tab:2
 *
 *
 * "Copyright (c) 2002 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
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
 * Authors:	Phil Levis <pal@cs.berkeley.edu>
 * Date:        Aug 21 2002
 * Desc:        Capsule type selector for CapsuleInjector.
 *
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
	
	group = new ButtonGroup();
	group.add(sub0Button);
	group.add(sub1Button);
	group.add(sub2Button);
	group.add(sub3Button);
	group.add(clockButton);
	group.add(sendButton);
	group.add(receiveButton);
	group.add(onceButton);

	add(sub0Button);
	add(sub1Button);
	add(sub2Button);
	add(sub3Button);
	add(clockButton);
	add(sendButton);
	add(receiveButton);
	add(onceButton);

	this.setAlignmentX(LEFT_ALIGNMENT);
    }
    
    public char getType() {
	// These hardcoded numbers should be made non-hardcoded at some
	// point - pal
	if (sub0Button.isSelected()) {return (char)0;}
	if (sub1Button.isSelected()) {return (char)1;}
	if (sub2Button.isSelected()) {return (char)2;}
	if (sub3Button.isSelected()) {return (char)3;}
	if (clockButton.isSelected())   {return (char)64;}
	if (sendButton.isSelected())    {return (char)65;}
	if (receiveButton.isSelected()) {return (char)66;}
	if (onceButton.isSelected())    {return (char)67;}
	return (char)-1;
    }
    
}
