package tools;

import java.io.*;

class CopyIn {
    Comm comm;

    CopyIn() {
	comm = new Comm();
	comm.start();
    }

    public static void main(String[] argv) {
	if (argv.length != 1) {
	    System.err.println("usage: java tools.CopyIn matchbox-filename");
	    System.err.println("  copies standard input to matchbox-filename");
	    System.exit(2);
	}
	new CopyIn().copy(argv[0]);
	System.exit(0);
    }

    void copy(String fname) {
	comm.checkedSend(new Op(FS.FSOP_WRITE_OPEN).
	    argString(fname).argBoolean(true).argBoolean(true));

	int maxData = Op.maxData - 2;
	byte[] buffer = new byte[maxData];
	for (;;) {
	    Op cmd = new Op(FS.FSOP_WRITE);

	    try {
		int actualData = System.in.read(buffer);
		if (actualData <= 0) 
		    break;

		cmd.argU8(actualData);
		cmd.argBytes(buffer, actualData);
		comm.checkedSend(cmd);
	    }
	    catch (IOException e) {
		System.err.println("error reading input");
		System.exit(1);
	    }

	}
	comm.checkedSend(new Op(FS.FSOP_WRITE_CLOSE));
    }
}
