package net.tinyos.social;

import javax.swing.*;
import java.awt.*;
import java.awt.event.*;
import java.util.*;

class GUI extends JPanel implements WindowListener, DBReceiver
{
    JScrollPane visitorPane;
    JTextArea visitorText;
    JPanel panel = new JPanel();
    JPanel panel2 = new JPanel();
    JTextField idField = new JTextField();
    JButton reqDataButton = new JButton();
    JButton quitButton = new JButton();
    String currentText = "";

    UserDB userDB;

    GUI(UserDB db)
    {
	userDB = db;
    }

    public void open()
    {
      try {
	  jbInit();
      }
      catch(Exception e) {
	  e.printStackTrace();
      }
      JFrame mainFrame = new JFrame("Ident");
      mainFrame.setSize(getPreferredSize());
      mainFrame.getContentPane().add("Center", this);
      mainFrame.show();
      mainFrame.addWindowListener(this);
    }

    public void dbChange(MoteInfo[] db)
    {
	/* Build display string */
	String display = "";
	MoteInfo elem;

	for (int i = 0; i < db.length; i++) 
	    if ((elem = db[i]) != null && elem.arrivalTime >= 0)
		display = display + elem.moteId + "," + i + " @ " + elem.arrivalTime + "\n";
	replaceText(display);
    }

    private void jbInit() throws Exception 
    {
	setMinimumSize(new Dimension(520, 160));
	setPreferredSize(new Dimension(520, 160));

	idField.setFont(new Font("Dialog", 1, 10));

	reqDataButton.addActionListener(new ActionListener()
	    {
		public void actionPerformed(ActionEvent e)
		{
		    int moteId = -1;

		    try {
			moteId = Integer.parseInt(idField.getText());
		    } 
		    catch (NumberFormatException foo) { }

		    if (moteId >= 0)
			userDB.sendReqData(moteId);
		}
	    });
	reqDataButton.setText("Req Data");
        reqDataButton.setFont(new Font("Dialog", 1, 10));

	quitButton.addActionListener(new ActionListener()
	    {
		public void actionPerformed(ActionEvent e)
		{
		    System.exit(0);
		}
	    });
	quitButton.setText("Exit");
        quitButton.setFont(new Font("Dialog", 1, 10));

	panel.setLayout(new GridLayout(4, 1));
	panel.setMinimumSize(new Dimension(150, 100));
	panel.setPreferredSize(new Dimension(150, 100));
	panel.add(idField, null);
	panel.add(reqDataButton, null);
	panel.add(quitButton, null);

	visitorText = new JTextArea();
	// We might get some text before we open. Set it. 
	replaceText(currentText);
	visitorPane = new JScrollPane(visitorText);

	panel2.setLayout(new BorderLayout());
	panel2.add(visitorPane, null);
	panel2.setPreferredSize(new Dimension(340, 100));

	add(panel2, BorderLayout.WEST);
	add(panel, BorderLayout.EAST);
    }

    synchronized void replaceText(String newText)
    {
	if (visitorText != null)
	    visitorText.replaceRange(newText, 0, currentText.length());
	currentText = newText;
    }

    public void windowClosing(WindowEvent e) { }
    public void windowClosed(WindowEvent e) { }
    public void windowActivated(WindowEvent e) { }
    public void windowIconified(WindowEvent e) { }
    public void windowDeactivated(WindowEvent e) { }
    public void windowDeiconified(WindowEvent e) { }
    public void windowOpened(WindowEvent e) { }
}
