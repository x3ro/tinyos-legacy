package	edu.mit.mers.localization;

import java.io.*;
import java.util.*;

public class GroundTruthDB {
    public ArrayList moteDB, moteFieldDB, tagDB;

    public GroundTruthDB(String fname) throws LocalizationException
    {
	moteDB = new ArrayList();
	moteFieldDB = new ArrayList();
	tagDB = new ArrayList();

	try {
	    BufferedReader reader = new BufferedReader(new FileReader(fname));
	    try {
		String line = reader.readLine();

		for(; line != null; line = reader.readLine()) {
		    GenericRecord current = GenericRecord.readRecord(line);
		    if (current != null) {
			if (current instanceof MoteRecord) { 
			    moteDB.add((MoteRecord)current);
			} else if (current instanceof MoteFieldRecord) {
			    moteFieldDB.add((MoteFieldRecord)current);
			} else if (current instanceof TagRecord) {
			    tagDB.add(current);
			}
		    }
		}
	    }
	    catch (IOException e) {
		throw new LocalizationException("IO Error reading DB file "
						+ fname + " : " + e.getMessage());
	    }
	}
	catch (FileNotFoundException e) {
	    throw new LocalizationException("File for reading not found: " + fname);
	}
    }

    public void writeDBtoFile(String fname) throws LocalizationException
    {

	try {
	    FileWriter fw;
	    try {
		fw = new FileWriter(fname);
	    }
	    catch (FileNotFoundException e) {
		throw new LocalizationException("File for writing not found: " + fname);
	    }
	
	    BufferedWriter writer = new BufferedWriter(fw);
	    MoteRecord current;
	    String s;
	    for(Iterator iter = moteDB.iterator(); iter.hasNext();) {
		current = (MoteRecord)(iter.next());
		s = current.toString();
		writer.write(s, 0, s.length());
		writer.newLine();
	    }
	    writer.close();
	}
	catch (IOException e) {
	    throw new LocalizationException("IO Error writing DB file "
					    + fname + " : " + e.getMessage());
	}
    }
}


