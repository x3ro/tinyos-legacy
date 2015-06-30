/*
 * Copyright (c) 2004-2006 Rincon Research Corporation.  
 * All rights reserved.
 * 
 * Rincon Research will permit distribution and use by others subject to
 * the restrictions of a licensing agreement which contains (among other things)
 * the following restrictions:
 * 
 *  1. No credit will be taken for the Work of others.
 *  2. It will not be resold for a price in excess of reproduction and 
 *      distribution costs.
 *  3. Others are not restricted from copying it or using it except as 
 *      set forward in the licensing agreement.
 *  4. Commented source code of any modifications or additions will be 
 *      made available to Rincon Research on the same terms.
 *  5. This notice will remain intact and displayed prominently.
 * 
 * Copies of the complete licensing agreement may be obtained by contacting 
 * Rincon Research, 101 N. Wilmot, Suite 101, Tucson, AZ 85711.
 * 
 * There is no warranty with this product, either expressed or implied.  
 * Use at your own risk.  Rincon Research is not liable or responsible for 
 * damage or loss incurred or resulting from the use or misuse of this software.
 */

/**
 * @author David Moss (dmm@rincon.com)
 */

package com.rincon.comports;

import java.util.Comparator;
import java.util.Enumeration;
import java.util.Iterator;
import java.util.Set;
import java.util.TreeSet;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import javax.comm.CommPortIdentifier;



public class ComPorts {

	/** Currently connected COM port */
	private String comPort;


	/**
	 * Constructor
	 * 
	 * @param printStatus
	 *            Print the status to the console if true
	 */
	public ComPorts() {
		Set comPorts = getComPorts();
		
		for (Iterator comIt = comPorts.iterator(); comIt.hasNext(); ) {
			comPort = (String) comIt.next();
			System.out.print(comPort + "\t");
		}
		System.out.println("");
	}

	/**
	 * Get a list of Strings with each available COMx port name
	 * 
	 * @return List of Strings
	 */
	private Set getComPorts() {
		Enumeration ports = CommPortIdentifier.getPortIdentifiers();

		Set listports = new TreeSet(
			// The following anonymous Comparator class ensures the
			// COMMPortIdentifier String names beginning with "COM"
			// are sorted by their integer COM port id value rather
			// than lexigraphically, e.g. COM2 < COM10.
			new Comparator() {
				public final int compare(Object p1, Object p2) {
					Pattern p = Pattern.compile("^(.*)(\\d+)$");
					Matcher m1 = p.matcher((String) p1);
					Matcher m2 = p.matcher((String) p2);
					if (m1.matches() && m2.matches()) {
						if (m1.group(1).equals(m2.group(1))) {
							p1 = new Integer(Integer.parseInt(m1.group(2)));
							p2 = new Integer(Integer.parseInt(m2.group(2)));
						} else {
							p1 = new String(m1.group(1));
							p2 = new String(m2.group(1));
						}
					}
					return ((Comparable) p1).compareTo(p2);
				}
			});

		while (ports.hasMoreElements()) {
			CommPortIdentifier current = (CommPortIdentifier) ports
					.nextElement();
			if (current.getPortType() == CommPortIdentifier.PORT_SERIAL) {
				if (!current.isCurrentlyOwned()) {
					listports.add(current.getName());
				}
			}
		}

		if (listports.size() == 0) {
			System.err.println("No COM ports found. Is win32comm.dll in the correct location?");
		}

		return listports;
	}

	public static void main(String[] args) {
		new ComPorts();
	}
}
