package net.tinyos.tinydb;

import java.io.*;
import java.util.*;

public class Config {
    // lines in 
    public static void init(String configFile) {
	try {
	    BufferedReader br = new BufferedReader(new InputStreamReader(new FileInputStream(configFile)));
	    String line;
	    String param, value;
	    short lineno = 0;

	    while ((line = br.readLine()) != null) {
		line = line.trim();
		lineno++;
		if (line.length() > 0 && line.charAt(0) != '%') {
		    StringTokenizer st = new StringTokenizer(line, ":");
		    try {
			param = st.nextToken().trim();
			value = st.nextToken().trim();
			opts.put(param, value);
			if (TinyDBMain.debug) System.out.println("param " + param + " set to " + value);
		    } catch (NoSuchElementException e) {
			System.out.println("Invalid config file entry, line " + lineno + ": " + line);
		    }
		}
	    }
	    
	} catch (IOException e) {
	    System.out.println("Config file error : " + e);
	}
    }
    
    public static String getParam(String param) {
	return (String)opts.get(param);
    }

    public static void setParam(String param, String value) {
	opts.put(param,value);
    }

    static Hashtable opts = new Hashtable();
}
