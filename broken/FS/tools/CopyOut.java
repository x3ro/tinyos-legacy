package tools;

import java.io.*;

class CopyOut {
    Comm comm;

    CopyOut() {
	comm = new Comm();
	comm.start();
    }

    public static void main(String[] argv) {
	if (argv.length != 1) {
	    System.err.println("usage: java tools.CopyOut matchbox-filename");
	    System.err.println("  copies matchbox-filename to standard output");
	    System.exit(2);
	}
	new CopyOut().copy(argv[0]);
	System.exit(0);
    }

    void copy(String fname) {
	comm.checkedSend(new Op(FS.FSOP_READ_OPEN).argString(fname));

	int maxData = Op.maxData - 2;
	byte[] buffer = new byte[maxData];
	for (;;) {
	    FSReplyMsg data =
	      comm.checkedSend(new Op(FS.FSOP_READ).argU8(maxData));

	    int count = data.getElement_data(0);
	    if (count == 0)
	      break;

	    for (int i = 1; i <= count; i++) 
	      System.out.print((char)data.getElement_data(i));
	}
	comm.checkedSend(new Op(FS.FSOP_READ_CLOSE));
    }
}
