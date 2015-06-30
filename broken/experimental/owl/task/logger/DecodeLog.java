import java.io.*;

class DecodeLog
{
    public static void main(String[] args) throws IOException {
	FileInputStream f = new FileInputStream(args[0]);
	int size = f.available();
	byte[] data = new byte[size];
	if (f.read(data, 0, size) != size) {
	    System.out.println("error reading");
	    System.exit(1);
	}
	f.close();

	for (int i = 0; i < size; i += 31) {
	    int time = (data[i] & 0xff) | ((data[i + 1] & 0xff) << 8) |
		((data[i + 2] & 0xff) << 16);
	    Tuple t = new Tuple(data, i + 3, 28);
	    String mask = "";
	    int nf = t.get_numFields();
	    int nn = t.get_notNull();
	    for (int j = 0; j < nf; j++)
		mask += (nn & (1 << j)) != 0 ? "1" : "0";
	    System.out.println("time " + time +
			       " qid " + t.get_qid() +
			       " nf " + nf +
			       " mask " + mask);

	    int offset = 0;
	    for (int j = 0; j < nf && j + 1 < args.length; j++) {
		if ((nn & (1 << j)) != 0) {
		    int val;

		    if (args[j + 1].charAt(0) == '1') {
			val = t.getElement_fields(offset) & 0xff;
			offset += 1;
		    }
		    else {
			val = (t.getElement_fields(offset) & 0xff) |
			    ((t.getElement_fields(offset + 1) & 0xff) << 8);
			offset += 2;
		    }

		    System.out.println("  " + args[j + 1] + " = " + val);
		}
	    }
	    System.out.println();
	}
    }
}
