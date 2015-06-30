package net.tinyos.straw;

public class TestStraw {
  private short dest = 2;
  private short portId = 7;
  private long start = 0;
  private long size = 20000;
  private byte[] data = new byte[(int)size];

  private short toUART = 0;
  private short verbose = 5;


  Straw straw = new Straw();


  public int execute(String[] args) {
    int argsIndex = 0;

    while (argsIndex < args.length) {
      if (args[argsIndex].equals("-d")) {
        dest = Short.parseShort(args[argsIndex + 1]);
	argsIndex += 2;
      } else if (args[argsIndex].equals("-p")) {
        portId = Short.parseShort(args[argsIndex + 1]);
	argsIndex += 2;
      } else if (args[argsIndex].equals("-st")) {
        start = Long.parseLong(args[argsIndex + 1]);
	argsIndex += 2;
      } else if (args[argsIndex].equals("-s")) {
        size = Long.parseLong(args[argsIndex + 1]);
	data = new byte[(int)size];
	argsIndex += 2;
      } else if (args[argsIndex].equals("-u")) {
        toUART = 1;
	argsIndex += 1;
      } else if (args[argsIndex].equals("-v")) {
        verbose = Short.parseShort(args[argsIndex + 1]);
	argsIndex += 2;
      }
    }
 
    straw.toUART = toUART;
    straw.verbose = verbose;
    straw.read(dest, portId, start, size, data);

    return 0;
  }


  public static void main(String[] args) {
    TestStraw ts = new TestStraw();
    System.exit(ts.execute(args));
  }
};
 
