package net.tinyos.tinydb;

import java.util.*;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;
import javax.swing.text.*;
import net.tinyos.message.*;

/** AddAttrPanel displays a dialog that allows a user to specify a new
(constant valued) attribute to add to the catalog.  The result is a
Message data structure which can be injected into the network to add
the attribute.  
<p>
A new attribute consists of three fields:
<ol>
<li> name: (up to) 8 bytes of name
<li> type: a tinydb type (except String) from QueryField
<li> value: a constant value (up to 4 bytes in size)
</ol>
@author Sam Madden (madden@cs.berkeley.edu)
*/
public class AddAttrPanel extends JDialog {
    boolean done;
    boolean ok;


    TinyDBType[] types = {new TinyDBType(QueryField.INTONE,"int8_t"),
				       new TinyDBType(QueryField.UINTONE,"uint8_t"),
				       new TinyDBType(QueryField.INTTWO,"int16_t"),
				       new TinyDBType(QueryField.UINTTWO,"uint16_t"),
				       new TinyDBType(QueryField.INTFOUR,"int32_t"),
				       new TinyDBType(QueryField.UINTFOUR,"uint32_t"),
				       new TinyDBType(QueryField.TIMESTAMP,"timestamp")
				      };

    FixedSizeField attrName = new FixedSizeField(8);
  JComboBox type = new JComboBox(types);
  NumberField attrValue = new NumberField(10);
  JLabel nameLabel = new JLabel("Attribute Name: ");
  JLabel valueLabel = new JLabel("Attribute Value: ");
  JLabel typeLabel = new JLabel("Attribute Type: ");
  JPanel namePanel = new JPanel(new GridLayout(1,2));
  JPanel valuePanel = new JPanel(new GridLayout(1,2));
  JPanel typePanel = new JPanel(new GridLayout(1,2));
  JLabel title = new JLabel("Specify a new constant attribute:    ");
  JPanel buttonPanel = new JPanel(new GridLayout(1,3));
  JButton okButton = new JButton("OK");
  JButton cancelButton = new JButton("Cancel");
  

    /** Constructor -- owner is the window that is causing the 
	addition
    */
    public AddAttrPanel(Frame owner) {
	super(owner,true);
	done= false;
    }

    /** Display the dialog 
	@return null if request was cancelled, otherwise the message
	that will add the new attribute
    */
   Message askForCommand() {
     Message cmd = null;
       initComponents();
       show();

       if (ok) {
	   
	    cmd = CommandMsgs.addAttrCmd((short)-1,attrName.getText().toCharArray(), (byte)types[type.getSelectedIndex()].type, new Long(attrValue.getText()).longValue());

       }

       
       return cmd;
    }
    
    private void done(boolean ok) {
	this.ok = ok;
	done = true;
	dispose();
    }


    private void initComponents() {
	JDialog frame = this;

	buttonPanel.add(new JLabel()); //dummy
	buttonPanel.add(cancelButton);
	buttonPanel.add(okButton);
		       
	attrName.setText("attr");
	namePanel.add(nameLabel);
	namePanel.add(attrName);
	
	attrValue.setText("0");
	valuePanel.add(valueLabel);
	valuePanel.add(attrValue);


	typePanel.add(typeLabel);
	typePanel.add(type);
	

	frame.getContentPane().setLayout(new GridLayout(6,1));
	frame.getContentPane().add(title);
	frame.getContentPane().add(namePanel);
	frame.getContentPane().add(typePanel);
	frame.getContentPane().add(valuePanel);
	frame.getContentPane().add(new JLabel()); //blank space
	frame.getContentPane().add(buttonPanel);

	okButton.addActionListener( new ActionListener() {
		public void actionPerformed(ActionEvent e) {
		    done(true);
		}
	    });

	cancelButton.addActionListener( new ActionListener() {
		public void actionPerformed(ActionEvent e) {
		    done(false);
		}
	    });
				    
	
	frame.pack();
    }

    /** Test routine */
    public static void main(String[] argv) {
	AddAttrPanel p = new AddAttrPanel(null);
	p.askForCommand();

    }

    /* ------------- Internal classes ------------- */
			  
    class TinyDBType {
	int type;
	String name;
	public TinyDBType(int type, String name) {
	    this.type = type;
	    this.name = name;
	}
	public String toString() {
	    return name;
	}
    }
   
    //constrain the value field to contain only numbers
    class NumberField extends JTextField {
	public NumberField(int cols) {
	    super(cols);
	}
	protected Document createDefaultModel() {
	    return new NumberDocument();
	}
	class NumberDocument extends PlainDocument
	{
	    public void insertString(int offs, String str, AttributeSet a) throws BadLocationException {
		boolean ok = true;
		for (int i = 0; i < str.length(); i++) {
		    if (!Character.isDigit(str.charAt(i))) ok = false;
		}
		if (ok) super.insertString(offs,str,a);
	    }
	}	
    }


    //constrain the name field to be a fixed number of characters or less
    class FixedSizeField extends JTextField {
	int len;

	public FixedSizeField(int cols) {
	    super(cols);
	    len = cols;

	}
	protected Document createDefaultModel() {
	    return new FixedSizeDocument();
	}
	class FixedSizeDocument extends PlainDocument
	{
	    public void insertString(int offs, String str, AttributeSet a) throws BadLocationException {
		if (getLength() + str.length() <= len) super.insertString(offs,str,a);
	    }
	}	
    }


}
