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
 * Desc:        Main window for Bombilla code injector.
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

/** This is a <code>test.timer</code> test of.the Javadoc utility. Cool.*/

public class CapsuleInjector extends JFrame {

    private JPanel      leftPanel;

    private JPanel      moteIDPanel;
    private JLabel      moteIDLabel;
    private JTextField   moteIDText;
    
    private JPanel      versionPanel;
    private JLabel      versionLabel;
    private JTextField  versionText;

    private JLabel      spacerLabel;
    
    private JPanel      selectionPanel;
    private JLabel      selectorLabel;
    private JLabel      optionLabel;
    private CapsuleSelector selector;
    private OptionSelector options;

    private JPanel      buttonPanel;
    private JButton     injectButton;
    private JButton     quitButton;
    
    private JPanel      rightPanel;
    private JLabel      programLabel;
    private JTextArea   programArea;

    private Sender      sender;

    private BombillaAssembler assembler;
    
    public CapsuleInjector(SerialStub stub) throws Exception {
	super("TinyOS VM Code Injector");
	sender = new Sender(stub, 0x7d);
	assembler = new BombillaAssembler();
	
	Font font = new Font("Courier", Font.PLAIN, 12);
	
	programArea = new JTextArea(24, 16);
	programArea.setFont(font);
	programLabel = new JLabel("Program Text");
	
	leftPanel = new JPanel();
	leftPanel.setLayout(new BoxLayout(leftPanel, BoxLayout.Y_AXIS));

	createMotePanel();
	createVersionPanel();
	spacerLabel = new JLabel("       ");
	createSelectionPanel();
	createButtonPanel(font);
	
	leftPanel.add(moteIDPanel);
	leftPanel.add(versionPanel);
	leftPanel.add(spacerLabel);
	leftPanel.add(selectionPanel);
	leftPanel.add(buttonPanel);
	
	rightPanel = new JPanel();
	
	rightPanel.setLayout(new BoxLayout(rightPanel, BoxLayout.Y_AXIS));
	rightPanel.add(programLabel);
	rightPanel.add(programArea);
	
	getContentPane().setLayout(new GridLayout(0, 2));
	
	getContentPane().add(leftPanel);
	getContentPane().add(rightPanel);

	setVisible(true);
	pack();
    }

    protected void inject() throws IOException, InvalidInstructionException  {
	String program = programArea.getText();
	StringReader reader = new StringReader(program);
	ProgramTokenizer tok = new ProgramTokenizer(reader);
	byte[] code = assembler.toByteCodes(tok);

	reader = new StringReader(program);
	tok = new ProgramTokenizer(reader);
	String codeStr = assembler.toHexString(tok);

	System.out.println("Sending program: " + codeStr);
	
	char type = selector.getType();
	int version = Integer.parseInt(versionText.getText(), 16);
	
	BombillaCapsuleMsg msg = new BombillaCapsuleMsg();
	msg.setType(type);
	msg.setOptions(options.getOptions());
	msg.setVersion((char)(version & 0xffff));
	for (int i = 0; i < code.length; i++) {
	    msg.setCode(i, code[i]);
	}

	int moteID = Integer.parseInt(moteIDText.getText(), 16);
	
	sender.send(moteID, msg);
    }
    
    private void createMotePanel() {
	moteIDPanel = new JPanel();
	moteIDPanel.setLayout(new BoxLayout(moteIDPanel, BoxLayout.X_AXIS));
	moteIDLabel = new JLabel("Mote ID");
	moteIDText = new JTextField("0", 4);
	moteIDPanel.add(moteIDLabel);
	moteIDPanel.add(moteIDText);
	moteIDText.setMaximumSize(new Dimension(60, 25));
	moteIDText.setMinimumSize(new Dimension(60, 25));
	moteIDPanel.setAlignmentX(RIGHT_ALIGNMENT);
    }
    
    private void createVersionPanel() {
	versionPanel = new JPanel();
	versionPanel.setLayout(new BoxLayout(versionPanel, BoxLayout.X_AXIS));
	
	versionLabel = new JLabel("Capsule Version");
	versionText = new JTextField("0", 4);
	versionPanel.add(versionLabel);
	versionPanel.add(versionText);
	versionText.setMaximumSize(new Dimension(60, 25));
	versionText.setMinimumSize(new Dimension(60, 25));
	versionPanel.setAlignmentX(RIGHT_ALIGNMENT);
    }

    private void createSelectionPanel() {
	selectionPanel = new JPanel();
	JPanel subLeftPanel = new JPanel();
	JPanel subRightPanel = new JPanel();

	subLeftPanel.setLayout(new BoxLayout(subLeftPanel, BoxLayout.Y_AXIS));
	subRightPanel.setLayout(new BoxLayout(subRightPanel, BoxLayout.Y_AXIS));
	selectionPanel.setLayout(new BoxLayout(selectionPanel, BoxLayout.X_AXIS));
	
	selectorLabel = new JLabel("Capsule Type");
	selector = new CapsuleSelector();
	selectorLabel.setAlignmentY(TOP_ALIGNMENT);
	selector.setAlignmentY(TOP_ALIGNMENT);
	
	optionLabel = new JLabel("Capsule Options");
	options = new OptionSelector();
	optionLabel.setAlignmentY(TOP_ALIGNMENT);
	options.setAlignmentY(TOP_ALIGNMENT);

	subLeftPanel.add(selectorLabel);
	subLeftPanel.add(selector);

	subRightPanel.add(optionLabel);
	subRightPanel.add(options);

	subLeftPanel.setAlignmentY(TOP_ALIGNMENT);
	subRightPanel.setAlignmentY(TOP_ALIGNMENT);
	subRightPanel.setAlignmentX(RIGHT_ALIGNMENT);
	
	selectionPanel.add(subLeftPanel);
	selectionPanel.add(subRightPanel);
	selectionPanel.setAlignmentX(RIGHT_ALIGNMENT);
    }

    private void createButtonPanel(Font font) {
	injectButton = new InjectButton(this);
	injectButton.setFont(font);
	injectButton.setAlignmentX(LEFT_ALIGNMENT);
	
	quitButton = new QuitButton();
	quitButton.setFont(font);
	injectButton.setAlignmentX(RIGHT_ALIGNMENT);
	
	buttonPanel = new JPanel();
	buttonPanel.setLayout(new BoxLayout(buttonPanel, BoxLayout.X_AXIS));
	buttonPanel.add(injectButton);
	buttonPanel.add(quitButton);
    }
    
    private class QuitButton extends JButton {
	public QuitButton() {
	    super("Quit");
	    addActionListener(new QuitListener());
	    setAlignmentX(CENTER_ALIGNMENT);
	}
	private class QuitListener implements ActionListener {
	    public void actionPerformed(ActionEvent e) {
		System.exit(0);
	    }
	}
    }

    private class InjectButton extends JButton {
	public InjectButton(CapsuleInjector inject) {
	    super("Inject");
	    addActionListener(new InjectListener(inject));
	    setAlignmentX(CENTER_ALIGNMENT);
	}

	private class InjectListener implements ActionListener {
	    private CapsuleInjector injector;
	    
	    public InjectListener(CapsuleInjector injector) {
		this.injector = injector;
	    }

	    public void actionPerformed(ActionEvent e) {
		try {
		    injector.inject();
		}
		catch (IOException exception) {
		    System.err.println("ERROR: Couldn't inject packet: " + exception);
		}
		catch (InvalidInstructionException exception) {
		    System.err.println("Invalid instruction: " + exception);
		}
	    }
	}
	
    }

    public static void main(String[] args) {
	try {
	    SerialStub sstub = new SerialPortStub("COM1");
	    sstub.Open();
	    CapsuleInjector window = new CapsuleInjector(sstub);
	} 
	
	catch (Exception e) {
	    e.printStackTrace();
	}
    }
    
    


    
}
