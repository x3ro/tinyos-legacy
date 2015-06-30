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
import javax.swing.*;
import Surge.*;
import Surge.Dialog.*;
import Surge.PacketAnalyzers.*;
import java.awt.event.*;
import javax.swing.event.*;
import java.beans.*;
import java.awt.*;

public class EdgeInfoPanel extends ActivePanel
{

	public EdgeInfoPanel()
	{
		tabTitle = "General";

		//{{INIT_CONTROLS
		setLayout(null);
		Insets ins = getInsets();
		setSize(280,270);
		JLabel1.setText("Edge Label:");
		add(JLabel1);
		JLabel1.setFont(new Font("Dialog", Font.BOLD, 16));
		JLabel1.setBounds(24,12,96,27);
		JTextField1.setNextFocusableComponent(JTextField2);
		add(JTextField1);
		JTextField1.setForeground(java.awt.Color.blue);
		JTextField1.setBounds(120,12,144,24);
		JLabel2.setText("Source Node Number:");
		add(JLabel2);
		JLabel2.setBounds(24,48,156,12);
		JLabel3.setText("Destination Node Number");
		add(JLabel3);
		JLabel3.setBounds(24,72,150,15);
		JLabel4.setText("jlabel");
		add(JLabel4);
		JLabel4.setBounds(192,48,36,12);
		JLabel5.setText("jlabel");
		add(JLabel5);
		JLabel5.setBounds(192,72,36,18);
		JLabel6.setText("Distance:");
		add(JLabel6);
		JLabel6.setBounds(24,96,147,16);
		JTextField2.setNextFocusableComponent(JTextField1);
		add(JTextField2);
		JTextField2.setBounds(192,96,45,24);
		//}}

		//{{REGISTER_LISTENERS
		//}}
	}

	//{{DECLARE_CONTROLS
	javax.swing.JLabel JLabel1 = new javax.swing.JLabel();
	javax.swing.JTextField JTextField1 = new javax.swing.JTextField();
	javax.swing.JLabel JLabel2 = new javax.swing.JLabel();
	javax.swing.JLabel JLabel3 = new javax.swing.JLabel();
	javax.swing.JLabel JLabel4 = new javax.swing.JLabel();
	javax.swing.JLabel JLabel5 = new javax.swing.JLabel();
	javax.swing.JLabel JLabel6 = new javax.swing.JLabel();
	javax.swing.JTextField JTextField2 = new javax.swing.JTextField();
	//}}

	public void ApplyChanges()
	{
		      //this function is called when the user clicks the "Apply" button
		      //on the dialog in which this Active Panel is displayed.
		      //It should apply the values of the display components
		      //to the variables they represent
	}

	public void InitializeDisplayValues()
	{
		      //This function is called by a thread that runs in the background
		      //and updates the values of the Active Panels so they are always
		      //up to date.
	}
}