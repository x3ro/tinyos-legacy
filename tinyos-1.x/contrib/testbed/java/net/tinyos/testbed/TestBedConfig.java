package net.tinyos.testbed;

import java.io.*;
import java.util.*;

/** Parses a testbed configuration file.
 *@author Rodrigo Fonseca (rfonseca at cs.berkeley.edu)
 */
public class TestBedConfig {
	private Vector motes;

	public TestBedConfig(String filename) throws FileNotFoundException {
		BufferedReader br;
		String line;	
		motes = new Vector();
		br = new BufferedReader( new FileReader(filename) );
		try {
			while ((line = br.readLine()) != null) {
			    StringTokenizer st = new StringTokenizer(line);
			    if(st.countTokens()==0) continue; 
			    if (st.nextToken().compareTo("mote") == 0) {
				//for (int i = 0; i < splitLine.length; i++) {
				//	System.err.print(splitLine[i] + " ** ");
				//}
				//System.out.println("Matches mote");
				int id;
				String address;
				double x,y;
				x = 0.0; y = 0.0;
				if (st.countTokens() < 2){
				    throw new Exception("Error parsing line: too few arguments" + line);
				}
				id = Integer.parseInt(st.nextToken());
				address = st.nextToken();
				if (st.countTokens() == 2) {
				    x = Double.parseDouble(st.nextToken());
				    y = Double.parseDouble(st.nextToken());
				}
				motes.add(new TestBedConfigMote(id,address,x,y));
			    }
			}
		} catch (Exception e) {
			e.printStackTrace();
			System.err.println(e);
			System.exit(0);
		}
	}

	public int getNumberOfMotes() {
		return motes.size();	
	}
	
	public TestBedConfigMote getMote(int i) throws IllegalArgumentException{
		if (i < 0 || i >= motes.size()) 
			throw new IllegalArgumentException();
		return (TestBedConfigMote)motes.elementAt(i);
	}

	public Iterator getMotesIterator() {
		return motes.iterator();
	}

	/**
        * When called standalone, this parses the config file provided and prints the information read.
	* Usage: TestBedConfig &lt;filename&gt;
	* @param filename
        */
	public static void main(String[] args) {
		if (args.length != 1) {
			System.out.println("TestBedConfig test: please provide the name of a config file\n");
			System.exit(0);
		}
		System.out.println("Testing TestBedConfig with file " + args[0]);
		TestBedConfig tb;
		try {
			tb = new TestBedConfig(args[0]);
	
			System.out.println("Read file with " + tb.getNumberOfMotes() + " motes");
			Iterator it = tb.getMotesIterator();
			TestBedConfigMote m;
	
			int i = 0;
			while (it.hasNext()) {
				m = (TestBedConfigMote)it.next();
				System.out.println("Index " + i + ": " + m);
				i++;
			}
			

		} catch (Exception e) {
			//e.printStackTrace();
			System.out.println(e);
			System.exit(0);
		}
	}

	public class TestBedConfigMote {
		private int id;
		private String address;
		private double x;
		private double y;

		public TestBedConfigMote(int id, String address, double x, double y) {
			this.id = id;
			this.address = address;
			this.x = x;
			this.y = y;
		}

		public TestBedConfigMote(int id, String address) {
			this(id,address,0.0,0.0);
		}	

		public int getId() {
			return id;
		}
		public void setId(int id) {
			this.id = id;
		}

		public String getAddress() {
			return address;
		}
		public void setAddress(String address) {
			this.address = address;
		}

		public double getX() {
			return x;
		}
		public void setX(double x) {
			this.x = x;
		}

		public double getY() {
			return y;
		}
		public void setY(double y) {
			this.y = y;
		}
		
		public String toString() {
			return "mote id " + id + " address " + address + " x " + x + " y " + y ; 
		}
	}
}
