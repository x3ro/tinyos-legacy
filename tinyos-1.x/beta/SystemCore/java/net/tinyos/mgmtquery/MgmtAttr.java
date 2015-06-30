package net.tinyos.mgmtquery;

public class MgmtAttr {
  public int id;
  public int length;
  public int fieldLength;

  MgmtAttr(int id, int length, int fieldLength) {
    this.id = id;
    this.length = length;
    this.fieldLength = fieldLength;
  }

  public String toString() {
    return "attr(id=" + id + ",len=" + length + ",fieldlen=" + fieldLength + ")";
  }
}
