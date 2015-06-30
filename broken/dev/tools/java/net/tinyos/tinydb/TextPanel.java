/*
 * TextQueryFrame.java
 * Main class to allow users to distribute queries over the network...
 * Created on July 12, 2002, 12:49 PM
 */

/**
 *
 * @author  kyle
 */

package net.tinyos.tinydb;

import net.tinyos.amhandler.*;

import java.awt.*;
import javax.swing.*;
import java.awt.event.*;
import java.util.*;
import javax.swing.border.*;
import java.io.*;

import net.tinyos.tinydb.awtextra.*;
import net.tinyos.tinydb.topology.*;

import net.tinyos.tinydb.parser.*;

public class TextPanel extends JPanel  {

    /** Creates new form QueryFrame */
    public TextPanel(TinyDBNetwork nw) {
	this.nw = nw;

	//init ui
	initComponents();
    }

    //construct the UI
    private void initComponents() {

	sqlString = new JTextArea();
	sqlString.setLineWrap(true);
	sqlString.setEditable(true);
        sqlString.setBorder(new LineBorder(new java.awt.Color(0, 0, 0)));
	if (Config.getParam("default-query") != null)
	    sqlString.setText(Config.getParam("default-query"));
	errorMessage = new JTextArea();
	errorMessage.setEditable(false);
	errorMessage.setLineWrap(true);
	errorMessage.setBorder(null);
	typeQueryLabel = new JLabel("Enter SQL Query:");
	errorMessageLabel = new JLabel("Error Messages:");

        setLayout(new AbsoluteLayout());
	add(errorMessageLabel, new AbsoluteConstraints(410, 50, -1, -1));
	add(errorMessage, new AbsoluteConstraints(410, 80, 175, 50));

	add(typeQueryLabel, new AbsoluteConstraints(0,0,-1,-1));
	add(sqlString, new AbsoluteConstraints(0, 30, 400, 200));

	final TextPanel queryFrame = this;
    }

    public void sendQuery() {
	byte qid = MainFrame.allocateQID();
	
	TinyDBQuery curQuery = null;
	
	curQuery = generateQuery(qid, epochDur);
	
	if (curQuery == null)
	    return;
	curQuery.setSQL(sqlString.getText());
	System.out.println(curQuery);
	
	ResultFrame rf = new ResultFrame(curQuery, nw);
	TinyDBMain.notifyAddedQuery(curQuery);
	rf.show();
	if (resultWins.size() <= (qid + 1))
	    resultWins.setSize(qid+1);
	resultWins.setElementAt(rf,qid);
	nw.sendQuery(curQuery);
    }

	

  public void setError(String txt) {
    errorMessage.setText(txt);
    setError = true;
  }

    /** Generate a TinyDBQuery to represent the SQL query
    */
  TinyDBQuery generateQuery(byte queryId, short epochDur) {
    System.out.println("Running query:  " + sqlString.getText());
    System.out.println("Query ID = " + queryId);

    Catalog.curCatalog = new Catalog("catalog");

    setError("");

    TinyDBQuery tdb_query = null;

    try {
	tdb_query = SensorQueryer.translateQuery(sqlString.getText(), queryId);
    } catch (ParseException pe) {
	setError(pe.getParseError());
	return null;
    }

    //    if (tdb_query == null)
    //	setError("Bad query syntax");

    return (tdb_query);
  }



    private JTextArea sqlString;
    private JTextArea errorMessage;
    private JLabel typeQueryLabel;
    private JLabel errorMessageLabel;
    
    Catalog c = new Catalog("catalog");
    boolean setError = false;
    short epochDur = 2048;
    boolean sendingQuery = false;
    TinyDBNetwork nw;
    Vector resultWins = new Vector();
}

