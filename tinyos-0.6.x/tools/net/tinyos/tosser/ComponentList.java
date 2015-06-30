package net.tinyos.tosser;

import java.io.File;
import java.util.*;


/** Given the file corresponding to the top level TOS directory (nest/tos),
    builds a list of available components. Uses the rene platform. */

public class ComponentList {
    private Hashtable table;
    private Vector vector;

    public ComponentList(File tosDirectory) {
	table = new Hashtable();
	vector = new Vector();
	buildComponentList(tosDirectory);
    }

    /** Returns a vector of TOSComponents, sorted lexicographically. */
    public Vector componentList() {
	return vector;
    }

    /* Scans an array of files for *.comp and *.desc and puts
       them in the class hash table. The scan order makes sure
       that higher priority files go in first, and if a duplicate
       is found, the older is kept. */
    private void scanFileList(File[] list, Hashtable table) {
	for (int i = 0; i < list.length; i++) {
	    String name = list[i].getName();
	    if (table.contains(name)) {
		return;
	    }
	    if (name.endsWith(".comp")) {
		String desc = name.substring(0, name.length() - 5);
		desc = desc + ".desc";
		if (!table.contains(desc)) {
		    table.put(name, new TOSComponent(list[i]));
		}
	    }
	    else if (name.endsWith(".desc")) {
		String comp = name.substring(0, name.length() - 5);
		comp = comp + ".comp";
		if (table.containsKey(comp)) {
		    table.remove(comp);
		}
		table.put(name, new TOSComponent(list[i]));
	    }
	}
    }

    private void buildComponentList(File tosDir) {
	File shared;
	File system;
	File platform;
	table = new Hashtable();
	
	shared = new File(tosDir, "shared");
	system = new File(tosDir, "system");
	platform = new File(tosDir, "platform/rene");

	scanFileList(platform.listFiles(), table);
	scanFileList(system.listFiles(), table);
	scanFileList(shared.listFiles(), table);

	Enumeration elems = table.elements();

	// Build the list
	while(elems.hasMoreElements()) {
	    vector.addElement(elems.nextElement());
	}

	// Sort the list
	for (int i = 0; i < vector.size(); i++) {
	    TOSComponent comp = (TOSComponent)vector.elementAt(i);
	    for (int j = i+1; j < vector.size(); j++) {
		TOSComponent comp2 = (TOSComponent)vector.elementAt(j);
		if (comp2.getName().compareTo(comp.getName()) < 0) {
		    comp = comp2;
		}
		else if (comp2.getName().compareTo(comp.getName()) == 0) {
		    if (!(comp2.isCompound()) && (comp.isCompound())) {
			comp = comp2;
		    }
		}
	    }
	    vector.remove(comp);
	    vector.insertElementAt(comp, i);
	}

	// Print out the list (for debugging, etc.)
	/*
	for (int i = 0; i < vector.size(); i++) {
	    TOSComponent comp = (TOSComponent)vector.elementAt(i);
	    if (comp.isCompound()) {
		//System.out.print("+");
	    }
	    //System.out.println(comp.name());
	}*/
    }
}
