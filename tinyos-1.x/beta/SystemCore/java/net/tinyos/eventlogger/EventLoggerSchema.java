package net.tinyos.eventlogger;

import java.io.*;
import java.util.*;
import java.util.regex.*;

import net.tinyos.util.*;
import net.tinyos.message.*;
import net.tinyos.multihop.*;

public class EventLoggerSchema {

  private HashMap schemaEntries = new HashMap();

  public EventLoggerSchema(String filename) {
    readSchema(filename);
  }

  private void readSchema(String filename) {
    try {
      BufferedReader in = new BufferedReader(new FileReader(filename));
      String str;
      while ((str = in.readLine()) != null) {
	processSchemaEntry(str);
      }
      in.close();
    } catch (IOException e) { }
  }

  private void processSchemaEntry(String line) {
    String[] tokens = line.split("\\s+",2);
	
    int key = Integer.parseInt(tokens[0]);
    String text = tokens[1].substring(1, tokens[1].length()-1);
    System.err.println("" + key + " (" + text + ")");
    
    SchemaEntry se = new SchemaEntry(key, text);
    schemaEntries.put(new Integer(key), se);
    //    parseText(text);
  }

  public String convertMessage(LogEntryMsg logEntry, 
			       int key) {

    SchemaEntry se = (SchemaEntry) schemaEntries.get(new Integer(key));
    if (se == null)
      return ("ERROR: Unknown Key (" + key + ")");

    String text = se.text;

    Pattern p = Pattern.compile("%\\d+[xd]");
    Matcher m = p.matcher(se.text);

    int offset = 0;

    while (m.find() && offset < logEntry.get_length()) {
      String arg = m.group();

      Pattern p1 = Pattern.compile("\\d+");
      Matcher m1 = p1.matcher(arg);
      
      int bytes = 0;
      if (m1.find()) {
	bytes = Integer.parseInt(m1.group());
      }
      
      int value = (int)getUIntElement(logEntry, offset * 8, bytes * 8);
      String valueString = "";
      if (arg.charAt(arg.length()-1) == 'd') {
	valueString = new Integer(value).toString();
      } else if (arg.charAt(arg.length()-1) == 'x') {
	valueString = Integer.toHexString(value);
      }
      text = text.replaceFirst("%\\d+[xd]", valueString);
      offset += bytes;
    }
    return text;
  }

  private class SchemaEntry {

    public int key;
    public String text;

    SchemaEntry(int key, String text) {
      this.key = key;
      this.text = text;
    }
  }

  private int ubyte(LogEntryMsg m,
		    int offset) {
    int val = m.getElement_data(offset);
    
    if (val < 0) return val + 256;
    else return val;
  }

  protected long getUIntElement(LogEntryMsg m, 
				int offset, int length) {
    int byteOffset = offset >> 3;
    int bitOffset = offset & 7;
    int shift = 0;
    long val = 0;
    
    while (length >= 8) {
      val |= (long)ubyte(m,byteOffset++) << shift;
      shift += 8;
      length -= 8;
    }
    
    return val;
  }

}
