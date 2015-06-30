package net.tinyos.social.names;

import javax.swing.*;
import java.awt.*;
import java.awt.event.*;
import java.util.*;

class GUI extends JPanel
{
    final static int MAX_NAME_LENGTH = 40;

    static void p(String s) { System.out.println(s); }

    JScrollPane namePane;
    JList nameList;
    JPanel panel = new JPanel();
    JPanel panel2 = new JPanel();
    JTextField idField = new JTextField();
    JTextField nameField = new JTextField();
    JButton addButton = new JButton();
    JButton setButton = new JButton();
    JButton delButton = new JButton();
    JButton quitButton = new JButton();

    UserDB db;

    GUI(UserDB db) {
	this.db = db;
    }

    void error(String s) {
	p(s);
    }

    public void open() {
      try {
	  jbInit();
      }
      catch(Exception e) {
	  e.printStackTrace();
      }
      JFrame mainFrame = new JFrame("Social Names");
      mainFrame.setSize(getPreferredSize());
      mainFrame.getContentPane().add(this, BorderLayout.CENTER);
      mainFrame.show();
    }

    private void jbInit() throws Exception {
	this.setLayout(new BorderLayout());
	setMinimumSize(new Dimension(650, 160));
	setPreferredSize(new Dimension(650, 160));

	idField.setFont(new java.awt.Font("Dialog", 1, 10));
	idField.addActionListener(new java.awt.event.ActionListener()
	    {
		public void actionPerformed(ActionEvent e) { addMote(); }
	    });
	addButton.addActionListener(new java.awt.event.ActionListener()
	    {
		public void actionPerformed(ActionEvent e) { addMote(); }
	    });
	addButton.setText("Add");
        addButton.setFont(new java.awt.Font("Dialog", 1, 10));

	nameField.setFont(new java.awt.Font("Dialog", 1, 10));
	nameField.addActionListener(new java.awt.event.ActionListener()
	    {
		public void actionPerformed(ActionEvent e) { setMoteName(); }
	    });
	setButton.addActionListener(new java.awt.event.ActionListener()
	    {
		public void actionPerformed(ActionEvent e) { setMoteName(); }
	    });
	setButton.setText("Set");
        setButton.setFont(new java.awt.Font("Dialog", 1, 10));

	delButton.addActionListener(new java.awt.event.ActionListener()
	    {
		public void actionPerformed(ActionEvent e) { delMote(); }
	    });
	delButton.setText("Del");
        delButton.setFont(new java.awt.Font("Dialog", 1, 10));

	quitButton.addActionListener(new java.awt.event.ActionListener()
	    {
		public void actionPerformed(ActionEvent e)
		{
		    System.exit(0);
		}
	    });
	quitButton.setText("Exit");
        quitButton.setFont(new java.awt.Font("Dialog", 1, 10));

	panel.setLayout(new GridLayout(3, 2));
	panel.setMinimumSize(new Dimension(300, 100));
	panel.setPreferredSize(new Dimension(300, 100));
	panel.add(idField, null);
	panel.add(addButton, null);
	panel.add(nameField, null);
	panel.add(setButton, null);
	panel.add(delButton, null);
	panel.add(quitButton, null);

	nameList = new JList(db);
	nameList.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
	namePane = new JScrollPane(nameList);

	panel2.setLayout(new BorderLayout());
	panel2.add(namePane, BorderLayout.CENTER);

	add(panel2, BorderLayout.CENTER);
	add(panel, BorderLayout.EAST);
    }

    void addMote() {
	int moteId = -1;

	try {
	    moteId = Integer.parseInt(idField.getText());
	} 
	catch (NumberFormatException foo) { }

	if (moteId >= 0) {
	    if (db.add(moteId) != null) {
		int index = db.lookupIndex(moteId);
		idField.setText("");
		nameList.ensureIndexIsVisible(index);
		nameList.setSelectedIndex(index);
	    }
	    else
		error("Duplicate id ");
	}
	else
	    error("Invalid mote id ");
    }

    void delMote() {
	if (nameList.isSelectionEmpty())
	    error("No mote selected");
	else
	    if (!db.delIndex(nameList.getSelectedIndex()))
		p("del BUG");
    }

    void setMoteName() {
	String name = nameField.getText().trim();

	if (name.equals(""))
	    error("No name given!");
	else if (name.length() > MAX_NAME_LENGTH)
	    error("Name too long (max is " + MAX_NAME_LENGTH + " characters)");
	else if (name.indexOf('"') != -1)
	    error("\" not allowed in names");
	else if (nameList.isSelectionEmpty())
	    error("No mote selected");
	else {
	    db.setNameByIndex(nameList.getSelectedIndex(), name);
	    nameField.setText("");
	}
    }
}
