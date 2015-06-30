/*									tab:2
 *
 *
 * "Copyright (c) 2001 and The Regents of the University 
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
 * Authors:		Phil Levis
 * Description:         A panel for entering packet data.
 * 
 */

package net.tinyos.packet;

import java.awt.*;
import java.awt.event.*;
import java.util.*;
import javax.swing.*;
import javax.swing.event.*;
import javax.swing.text.*;
    
public class PacketPanel extends JPanel {
    private JTabbedPane pane;
    
    public PacketPanel() {
	pane = new JTabbedPane();
	add(pane);
	pane.setAlignmentX(LEFT_ALIGNMENT);
    }

    public PacketPanel(TOSPacket[] packets) {
	pane = new JTabbedPane();
	for (int i = 0; i < packets.length; i++) {
	    addPacketType(packets[i]);
	}
	add(pane);
	pane.setAlignmentX(LEFT_ALIGNMENT);
    }

    public PacketPanel(Vector packets) {
	pane = new JTabbedPane();
	for (int i = 0; i < packets.size(); i++) {
	    addPacketType((TOSPacket)packets.elementAt(i));
	}
	add(pane);
	pane.setAlignmentX(LEFT_ALIGNMENT);
    }

    public void addPacketType(TOSPacket packet) {
	PacketDisplayPanel panel = new PacketDisplayPanel(packet);

	Font font = new Font("Courier", Font.PLAIN, 12);
	panel.setFont(font);
	String name = packet.getClass().getName();
	name = name.substring(name.lastIndexOf('.') + 1);
	pane.add(panel, name);
    }
    
    public TOSPacket getPacket() {
	PacketDisplayPanel display = (PacketDisplayPanel)pane.getSelectedComponent();
	return display.getPacket();
    }

    protected class PacketDisplayPanel extends JPanel {
	private TOSPacket packet;
	private PacketOneByteField[] oneFields;
	private PacketTwoByteField[] twoFields;
	private PacketFourByteField[] fourFields;
	private PacketEightByteField[] eightFields;
	private PacketByteArrayField[] arrayFields;
	
	public PacketDisplayPanel(TOSPacket packet) {
	    super();
	    this.packet = packet;
	    //new BoxLayout(this, BoxLayout.Y_AXIS);
	    //this.setLayout(new BoxLayout(this, BoxLayout.Y_AXIS));

	    this.setLayout(new GridLayout(0,1));

	    this.setAlignmentX(LEFT_ALIGNMENT);
	    String[] fields;

	    try {
		fields = packet.getByteFieldNames();
		oneFields = new PacketOneByteField[fields.length];
		for (int i = 0; i < fields.length; i++) {
		    String fullname = fields[i];
		    oneFields[i] = new PacketOneByteField(fields[i]);
		    byte val = packet.getClass().getField(fullname).getByte(packet);
		    oneFields[i].setValue(val);
		    this.add(oneFields[i]);
		}
		
		fields = packet.getTwoByteFieldNames();
		twoFields = new PacketTwoByteField[fields.length];
		for (int i = 0; i < fields.length; i++) {
		    String fullname = fields[i];
		    twoFields[i] = new PacketTwoByteField(fields[i]);
		    short val = packet.getClass().getField(fullname).getShort(packet);
		    twoFields[i].setValue(val);
		    this.add(twoFields[i]);
		}
		
		fields = packet.getFourByteFieldNames();
		fourFields = new PacketFourByteField[fields.length];
		for (int i = 0; i < fields.length; i++) {
		    String fullname = fields[i];
		    fourFields[i] = new PacketFourByteField(fields[i]);
		    int val = packet.getClass().getField(fullname).getInt(packet);
		    fourFields[i].setValue(val);
		    this.add(fourFields[i]);
		}
		
		fields = packet.getEightByteFieldNames();
		eightFields = new PacketEightByteField[fields.length];
		for (int i = 0; i < fields.length; i++) {
		    String fullname = fields[i];
		    eightFields[i] = new PacketEightByteField(fields[i]);
		    long val = packet.getClass().getField(fullname).getLong(packet);
		    eightFields[i].setValue(val);
		    this.add(eightFields[i]);
		}
		
		fields = packet.getByteArrayFieldNames();
		arrayFields = new PacketByteArrayField[fields.length];
		for (int i = 0; i < fields.length; i++) {
		    
		    try {
			String fullname = fields[i];
			int len = packet.getByteArrayLength(fields[i]);
			arrayFields[i] = new PacketByteArrayField(fields[i], len);
			byte[] field = (byte[])packet.getClass().getField(fullname).get(packet);
			arrayFields[i].setValue(field);
			this.add(arrayFields[i]);
			
		    }
		    catch (Exception exception) {
			System.err.println("An internal error occured with building the GUI for a packet type. It will be missing the " + fields[i] + " field.");
			exception.printStackTrace();
		    }
		}
	    }
	    catch (Exception exception) {
		System.err.println("An internal error occured with building the GUI for a packet type. It will be missing fields. Error:");
		exception.printStackTrace();
	    }
	}
	
	public TOSPacket getPacket() {
	    try {
		for (int i = 0; i < oneFields.length; i++) {
		    PacketOneByteField field = oneFields[i];
		    packet.setOneByteField(field.getName(), field.getValue());
		}
		
		for (int i = 0; i < twoFields.length; i++) {
		    PacketTwoByteField field = twoFields[i];
		    packet.setTwoByteField(field.getName(), field.getValue());
		}
		
		for (int i = 0; i < fourFields.length; i++) {
		    PacketFourByteField field = fourFields[i];
		    packet.setFourByteField(field.getName(), field.getValue());
		}
		
		for (int i = 0; i < eightFields.length; i++) {
		    PacketEightByteField field = eightFields[i];
		    packet.setEightByteField(field.getName(), field.getValue());
		}
		
		for (int i = 0; i < arrayFields.length; i++) {
		    PacketByteArrayField field = arrayFields[i];
		    packet.setByteArrayField(field.getName(), field.getValue());
		}
		
	    }
	    catch (Exception exception) {
		System.err.println("An internal error occured with the GUI data to packet translation. The packet is invalid");
		exception.printStackTrace();
	    }

	    return packet;
	}
    }

    private class PacketOneByteField extends JPanel {
	private String name;
	private JLabel label;
	private JTextField field;
	
	public PacketOneByteField(String name) {
	    super();
	    this.name = name;
	    
	    label = new JLabel(name + "    ");
	    field = new JTextField();
	    field.setDocument(new LimitedStyledDocument(2));
	    field.setText("00");

	    Font font = new Font("Courier", Font.PLAIN, 12);
	    field.setFont(font);

	    label.setAlignmentX(LEFT_ALIGNMENT);
	    field.setAlignmentX(RIGHT_ALIGNMENT);
	    field.setSize(30, 20);
	    field.setMaximumSize(field.getSize());
	    
	    add(label);
	    add(field);
	    
	    this.setLayout(new BoxLayout(this, BoxLayout.X_AXIS));
	    this.setAlignmentX(LEFT_ALIGNMENT);
	}

	public String getName() {
	    return name;
	}

	public byte getValue() throws NumberFormatException {
	    return (byte)(Integer.parseInt(field.getText(), 16) & 0xff); 
	}

	public void setValue(byte val) throws NumberFormatException {
	    field.setText(Integer.toString((int)(val & 0xff), 16));
	}
    }

    private class PacketTwoByteField extends JPanel {
	private String name;
	private JLabel label;
	private JTextField field;
	
	public PacketTwoByteField(String name) {
	    super();
	    this.name = name;
	    
	    label = new JLabel(name + "    ");
	    field = new JTextField();
	    field.setDocument(new LimitedStyledDocument(4));
	    field.setText("0000");

	    Font font = new Font("Courier", Font.PLAIN, 12);
	    field.setFont(font);

	    label.setAlignmentX(LEFT_ALIGNMENT);
	    field.setAlignmentX(RIGHT_ALIGNMENT);
	    field.setSize(60, 20);
	    field.setMaximumSize(field.getSize());
 
	    add(label);
	    add(field);
	    this.setLayout(new BoxLayout(this, BoxLayout.X_AXIS));
	    this.setAlignmentX(LEFT_ALIGNMENT);
	}

	public String getName() {
	    return name;
	}

	public short getValue() throws NumberFormatException {
	    return (short)(Integer.parseInt(field.getText(), 16) & 0xffff); 
	}

	public void setValue(short val) throws NumberFormatException {
	    field.setText(Integer.toString((int)(val & 0xffff), 16));
	}
    }

    private class PacketFourByteField extends JPanel {
	private String name;
	private JLabel label;
	private JTextField field;
	
	public PacketFourByteField(String name) {
	    super();
	    this.name = name;
	    
	    label = new JLabel(name + "    ");
	    field = new JTextField();
	    field.setDocument(new LimitedStyledDocument(8));
	    field.setText("00000000");

	    Font font = new Font("Courier", Font.PLAIN, 12);
	    field.setFont(font);

	    label.setAlignmentX(LEFT_ALIGNMENT);
	    field.setAlignmentX(RIGHT_ALIGNMENT);
	    field.setSize(120, 20);
	    field.setMaximumSize(field.getSize());
		    
	    add(label);
	    add(field);
	    this.setLayout(new BoxLayout(this, BoxLayout.X_AXIS));
	    this.setAlignmentX(LEFT_ALIGNMENT);
	}

	public String getName() {
	    return name;
	}

	public int getValue() throws NumberFormatException {
	    return Integer.parseInt(field.getText(), 16); 
	}

	public void setValue(int val) throws NumberFormatException {
	    field.setText(Integer.toString(val, 16));
	}
    }

    private class PacketEightByteField extends JPanel {
	private String name;
	private JLabel label;
	private JTextField field;
	
	public PacketEightByteField(String name) {
	    super();
	    this.name = name;
	    
	    label = new JLabel(name + "    ");
	    field = new JTextField();
	    field.setDocument(new LimitedStyledDocument(16));
	    field.setText("0000000000000000");
	    
	    Font font = new Font("Courier", Font.PLAIN, 12);
	    field.setFont(font);

	    label.setAlignmentX(LEFT_ALIGNMENT);
	    field.setAlignmentX(RIGHT_ALIGNMENT);
	    field.setSize(240, 20);
	    field.setMaximumSize(field.getSize());
	    
	    add(label);
	    add(field);
	    this.setLayout(new BoxLayout(this, BoxLayout.X_AXIS));
	    this.setAlignmentX(LEFT_ALIGNMENT);
	}

	public String getName() {
	    return name;
	}

	public long getValue() throws NumberFormatException {
	    return Long.parseLong(field.getText(), 16); 
	}

	public void setValue(long val) throws NumberFormatException {
	    String text = "";
	    text += Integer.toString((int)((val >> 32) & 0xffffff), 16);
	    text += Integer.toString((int)((val) & 0xffffff), 16);
	    field.setText(text);
	}
    }
    
    private class PacketByteArrayField extends JPanel {
	
	private String name;
	private int size;
	private JLabel label;
	private JTextField[] fields;
	
	public PacketByteArrayField(String name, int numBytes) {
	    super();
	    this.name = name;
	    this.setLayout(new FlowLayout());
	    this.setAlignmentX(LEFT_ALIGNMENT);
	    //this.setPreferredSize(new Dimension(1000, 20));
	    
	    label = new JLabel(name + "    ");
	    fields = new JTextField[numBytes];
	    size = numBytes;

	    label.setAlignmentX(LEFT_ALIGNMENT);
	    add(label);

	    Font font = new Font("Courier", Font.PLAIN, 12);
	    
	    for (int i = 0; i < numBytes; i++) {
		fields[i] = new JTextField();
		fields[i].setDocument(new LimitedStyledDocument(2));
		fields[i].setText("00");
		fields[i].setFont(font);

		fields[i].setAlignmentX(RIGHT_ALIGNMENT);
		fields[i].setSize(20, 20);
		fields[i].setPreferredSize(new Dimension(20,20));
		fields[i].setMinimumSize(new Dimension(50,20));
		fields[i].setMaximumSize(fields[i].getSize());

		add(fields[i]);
	    }
	    this.setAlignmentX(LEFT_ALIGNMENT);
	}

	public String getName() {
	    return name;
	}

	public byte[] getValue() throws NumberFormatException {
	    byte [] data = new byte[size];
	    for (int i = 0; i < size; i++) {
		String chunk = fields[i].getText();
		byte val = (byte)(Integer.parseInt(chunk, 16) & 0xff);
		data[i] = val;
	    }

	    return data;
	}

	public void setValue(byte[] val) throws NumberFormatException {
	    if (val.length > size) {
		throw new NumberFormatException("Attempted to set array of size " + size + " to larger array of size " + val.length);
	    }

	    for (int i = 0; i < val.length; i++) {
		String text = Integer.toString((int)(val[i] & 0xff), 16);
		fields[i].setText(text);
	    }
	}
    }

    // Do not call this function. It only exists so the demo GUI can work
    // without needing another source file.
    private JButton makeButton() {
	return new PacketButton(this);
    }
    
    public static void main(String[] args) {
	TOSPacket[] packets = new TOSPacket[3];
	//packets[0] = new NAMINGPacket();
	packets[1] = new AMPacket();
	//packets[2] = new BLESSPacket();

	
	JFrame frame = new JFrame();
	PacketPanel panel = new PacketPanel(packets);
	JButton button = panel.makeButton();
	
	frame.getContentPane().setLayout(new BoxLayout(frame.getContentPane(), BoxLayout.Y_AXIS));
	frame.getContentPane().add(panel);
	frame.getContentPane().add(button);
	frame.pack();
	frame.setVisible(true);
    }

    private class PacketButton extends JButton {
	
	public PacketButton(PacketPanel panel) {
	    super("Print Packet");
	    addActionListener(new PrintPacketActionListener(panel));
	}

	private class PrintPacketActionListener implements ActionListener {
	    private PacketPanel panel;
	    
	    public PrintPacketActionListener(PacketPanel p) {
		panel = p;
	    }

	    public void actionPerformed(ActionEvent e) {
		System.out.println(TOSPacket.dataToString(panel.getPacket().toByteArray()));
	    }
	}
    }

    private class LimitedStyledDocument extends DefaultStyledDocument {
	private int size;
	
	public LimitedStyledDocument(int size) {
	    this.size = size;
	}

	public void insertString(int offs, String str, AttributeSet a) throws BadLocationException {
            if ((getLength() + str.length()) <= size) {
                super.insertString(offs, str, a);
	    }
            else {
                Toolkit.getDefaultToolkit().beep();
	    }
        }
    }

}





