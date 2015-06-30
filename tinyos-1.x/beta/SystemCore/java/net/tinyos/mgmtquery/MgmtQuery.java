package net.tinyos.mgmtquery;

import java.util.*;

public class MgmtQuery {

  private int samplePeriod;
  private ArrayList keyList;
  private boolean ramQuery;

  public MgmtQuery(int samplePeriod) {
    this.samplePeriod = samplePeriod;
    keyList = new ArrayList();
  }

  public void appendKey(int id, int length) {
    keyList.add(new MgmtAttr(id, length, length));
  }

  public void appendKey(int id, int length, int fieldLength) {
    keyList.add(new MgmtAttr(id, length, fieldLength));
  }

  public int numAttrs() {
    return keyList.size();
  }

  public int samplePeriod() {
    return samplePeriod;
  }

  public ArrayList keyList() {
    return keyList;
  }

  public void setRAMQuery(boolean rq) {
    ramQuery = rq;
  }

  public boolean isRAMQuery() {
    return ramQuery;
  }

  public String toString() {
    return "period=" + samplePeriod + " ramQuery=" + ramQuery + "\n" + keyList;
  }
}
