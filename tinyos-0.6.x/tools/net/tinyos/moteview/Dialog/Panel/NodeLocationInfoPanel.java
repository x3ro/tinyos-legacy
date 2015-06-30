/* "Copyright (c) 2001 and The Regents of the University
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
* Authors:   Kamin Whitehouse <kamin@cs.berkeley.edu>
* History:   created 7/22/2001
*/

package net.tinyos.moteview.Dialog.Panel;

              //this file is used for visually creating the panel using VCafe,
              //it is then inserted into another class as an inner class and edited

import Surge.*;
import Surge.Dialog.*;
import java.beans.*;
import java.awt.*;
import javax.swing.JLabel;
import javax.swing.JTextField;
import javax.swing.JCheckBox;

public class NodeLocationInfoPanel extends Surge.Dialog.ActivePanel
{
	Node node;

	public NodeLocationInfoPanel(Node pNode)
	{
		tabTitle = "General";
		node = pNode;
		//{{INIT_CONTROLS
		setLayout(null);
		Insets ins = getInsets();
		setSize(247,168);
		JLabel3.setText("X Coordinate");
		add(JLabel3);
		JLabel3.setBounds(36,48,84,24);
		JLabel4.setText("Y Coordinate");
		add(JLabel4);
		JLabel4.setBounds(36,72,75,24);
		JTextField1.setNextFocusableComponent(JTextField2);
		JTextField1.setToolTipText("The scale of the coordinate system is determined by the user, and scaled automatically by the system to fit to the screen");
		JTextField1.setText("1.5");
		add(JTextField1);
		JTextField1.setBounds(120,48,87,18);
		JTextField2.setToolTipText("The scale of the coordinate system is determined by the user, and scaled automatically by the system to fit to the screen");
		JTextField2.setText("3.2");
		add(JTextField2);
		JTextField2.setBounds(120,72,87,18);
		JCheckBox1.setToolTipText("Check this is you don\'t want the node to move around");
		JCheckBox1.setText("Fixed x/y Coordinates");
		add(JCheckBox1);
		JCheckBox1.setBounds(36,96,168,24);
		//}}

		//{{REGISTER_LISTENERS
		//}}
	}

	//{{DECLARE_CONTROLS
	javax.swing.JLabel JLabel3 = new javax.swing.JLabel();
	javax.swing.JLabel JLabel4 = new javax.swing.JLabel();
	javax.swing.JTextField JTextField1 = new javax.swing.JTextField();
	javax.swing.JTextField JTextField2 = new javax.swing.JTextField();
	javax.swing.JCheckBox JCheckBox1 = new javax.swing.JCheckBox();
	//}}

	public void ApplyChanges()
	{
/*		node.SetX(Double.valueOf(JTextArea1.getText()).doubleValue());
		node.SetY(Double.valueOf(JTextArea2.getText()).doubleValue());
		node.SetFixed(JCheckBox1.isSelected());
		node.SetDisplayThisNode(JCheckBox2.isSelected());*/
	}

}