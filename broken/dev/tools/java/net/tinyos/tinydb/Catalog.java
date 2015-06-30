package net.tinyos.tinydb;

import java.io.*;
import java.util.*;

public class Catalog {
    public static Catalog curCatalog;
    public String fileName;

    public Catalog() {
	attrs = new Vector();
	fileName = null;
    }

    public Catalog(String catalogFile) {
	this();
	fileName = catalogFile;

	try {
	    BufferedReader r = new BufferedReader(new InputStreamReader(new FileInputStream(new File(catalogFile))));
	    String line;
	    while ((line = r.readLine()) != null) {
		if (line.trim().charAt(0) != '#' && line.trim().length() > 0)
		    addAttr(new QueryField(line, QueryField.INTTWO));
	    }
	    r.close();
	} catch (IOException e) {
	    System.out.println("Couldn't open catalog file : " + catalogFile);
	}
    }

    public int numAttrs() {
	return attrs.size();
    }

    public QueryField getAttr(int idx) {
	return (QueryField)attrs.elementAt(idx);
    }

    public QueryField getAttr(String name) {
	Enumeration e = attrs.elements();
	while (e.hasMoreElements()) {
	    QueryField qf = (QueryField)e.nextElement();
	    if (qf.getName().equals(name)) return qf;
	}
	return null;
    }

    public void addAttr(QueryField f, boolean log) {
	attrs.addElement(f);
	if (fileName != null && log) {
	    try {
		FileWriter fw = new FileWriter(fileName, true);
		
		fw.write(f.getName() + "\n");
		fw.close();
	    } catch (IOException e) {
	    }
	}

    }

    public void addAttr(QueryField f) {
	addAttr(f,false);
    }

    
    public static void main(String[] argv) {
	Catalog c = new Catalog("catalog");
	QueryField f = new QueryField("test",(byte)0);
	c.addAttr(f,true);
    }

    private Vector attrs;
}
