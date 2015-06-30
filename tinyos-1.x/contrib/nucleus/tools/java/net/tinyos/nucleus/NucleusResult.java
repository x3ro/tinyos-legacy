package net.tinyos.nucleus;

import java.util.*;

public class NucleusResult {
  public int from;
  public byte[] bytes;
  public Map attrs;
  
  public NucleusResult() {
    attrs = new HashMap();
  }
  
  public boolean equals(Object o) {
    NucleusResult nr = (NucleusResult) o;
    return (from == nr.from);
  }
}
