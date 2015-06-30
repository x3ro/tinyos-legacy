package net.tinyos.ident;

import net.tinyos.util.*;
import java.io.*;

public class Ident {
    static final int MAX_ID_LENGTH = 15;

    static MoteIF moteIF;
    static UserDB userDB;
    static GUI gui;

    static void usage() 
    {
	System.err.println("Usage: java net.tinyos.ident.Ident group_id");
	System.exit(2);
    }

    public static void main(String[] argv) throws IOException {
	if (argv.length != 1)
	    usage();
	byte group_id = (byte) Integer.parseInt(argv[0]);

	userDB = new UserDB();
	moteIF = new MoteIF(group_id, userDB);
	gui = new GUI(moteIF, userDB);

	userDB.start();
	moteIF.start();
	gui.open();
    }
}    
