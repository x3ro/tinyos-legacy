package straw;

public class TestStraw {
  Counter bcastSeqNo = new Counter("Straw_BcastSeqNo.txt"); // only for Bcast
  Straw straw = new Straw();

  public int execute(String[] args) {
    short dest = 2;
    long start = 0;
    long size = 20000;
    byte[] data = new byte[(int)size];
    
    straw.read(dest, start, size, data);

    return 0;
  }

  public static void main(String[] args) {
    TestStraw ts = new TestStraw();
    System.exit(ts.execute(args));
  }
};
 
