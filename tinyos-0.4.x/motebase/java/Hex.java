public class Hex {
    
  public static final String[] hex = {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"};

  public static String toHex(int i) {
    int q = i/16;
    int r = i % 16;
    return (hex[q] + hex[r]);
  }

  public static String toHex(byte[] bytes) {
    return toHex(bytes, bytes.length);
  }

  public static String toHex(byte[] bytes, int length) {
    String result ="";
    for (int i = 0; i < length; i++) {
      byte b = bytes[i];
      int h = ((b & 0xf0) >> 4);
      int l = (b & 0x0f);
      result += hex[h] + hex[l] + " ";
    }
    return result;
  }

}
