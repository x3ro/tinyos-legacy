package net.tinyos.social.names;

import net.tinyos.util.*;
import java.io.*;

public class Names {

    static void usage() 
    {
	System.err.println("Usage: java net.tinyos.social.Names");
	System.exit(2);
    }

    public static void main(String[] argv) throws IOException {
	if (argv.length > 0)
	    usage();

	UserDB db = new UserDB();
	GUI gui = new GUI(db);
	gui.open();
    }
}    
