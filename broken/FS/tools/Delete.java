package tools;

import java.io.*;

class Delete {
    Comm comm;

    Delete() {
	comm = new Comm();
	comm.start();
    }

    public static void main(String[] argv) {
	if (argv.length != 1) {
	    System.err.println("usage: java tools.Delete matchbox-filename");
	    System.err.println("  deletes matchbox-filename");
	    System.exit(2);
	}
	new Delete().exec(argv[0]);
	System.exit(0);
    }

    void exec(String fname) {
	comm.checkedSend(new Op(FS.FSOP_DELETE).argString(fname));
    }
}
