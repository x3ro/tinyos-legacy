package net.tinyos.tinydb;

import java.io.*;
import java.util.*;

public class Catalog {
    public Catalog() {
	attrs = new Vector();
    }

    public Catalog(String catalogFile) {
	this();

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

    public void addAttr(QueryField f) {
	attrs.addElement(f);
    }
    

    private Vector attrs;
}
