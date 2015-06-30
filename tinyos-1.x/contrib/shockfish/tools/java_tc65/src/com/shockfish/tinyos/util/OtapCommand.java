package com.shockfish.tinyos.util;


public class OtapCommand {
    
    public final static String ARG_SEP = ";";

    public static String[] getArgs(String argStr) {
	try {
	    // find nb of args
	    int nbArgs = 0;
	    for (int i=0;i<argStr.length();i++) {
		if (argStr.substring(i,i+1).equals(ARG_SEP)) {
		    nbArgs++;
		}
	    }
	    // 2nd pass
	    String[] args = new String[nbArgs];
	    int aidx = 0;
	    int lastidx = 0;
	    for (int i=0;i<argStr.length();i++) {
		if (argStr.substring(i,i+1).equals(ARG_SEP)) {
		    args[aidx] = argStr.substring(lastidx, i);
		    aidx++;
		}
	    }
	    return args;
	} catch (Exception e) {
	    e.printStackTrace();
	    return null;
	}
    }
    

}