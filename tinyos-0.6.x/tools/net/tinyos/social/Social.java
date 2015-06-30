package net.tinyos.social;

import net.tinyos.util.*;
import java.io.*;

public class Social {
    final static int MAX_LOCAL_IDS = 64;

    static UserDB userDB;
    static GUI gui;

    static void usage() 
    {
	System.err.println("Usage: java net.tinyos.social.Social group_id id1 host1 port1 [id2 host2 port2 ...]");
	System.exit(2);
    }

    public static void main(String[] argv) throws IOException {
	if (argv.length < 3 || ((argv.length - 1) % 3) != 0)
	    usage();
	byte group_id = (byte) Integer.parseInt(argv[0]);

	userDB = new UserDB();
	gui = new GUI(userDB);
	userDB.setDBListener(gui);
	userDB.start();
	gui.open();

	/* Start all interfaces */
	for (int i = 1; i < argv.length; i += 3) {
	    int id = Integer.parseInt(argv[i]);
	    int port = Integer.parseInt(argv[i + 2]);
	    new MoteIF(id, argv[i + 1], port, group_id, userDB).start();
	}
    }
}    
