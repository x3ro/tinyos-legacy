package com.shockfish.tinyos.util;

import java.util.Enumeration;
import java.util.Hashtable;
import java.util.Vector;

import com.shockfish.tinyos.tools.CldcLogger;

public class ToolBox {
  
  public final static char PAIRS_SEP = ';'; // to separate couple in NodeMap
  public final static char VALUES_SEP = ',';

  /**
   * @return , if str is null, null is return
   */
  public static String[] split (String str, char c) {
    if (str == null)
      return null;
    
    // search for all the c in str
    Vector posOfC = new Vector();
    int lastPos = -1;
    while (str.indexOf(c, lastPos + 1) != -1) {
      lastPos = str.indexOf(c, lastPos + 1);
      posOfC.addElement(new Integer(lastPos));
    }
    
    String[] response = new String[posOfC.size() + 1];
    
    // make the substring
    int subStringBegin = 0;
    Integer subStringLast;
    for (int i = 0; i < response.length; i++) {
      if (posOfC.size() != 0)
        subStringLast = (Integer) posOfC.firstElement();
      else
        subStringLast = new Integer(str.length());
      
      posOfC.removeElement(subStringLast);
      response[i] = str.substring(subStringBegin, subStringLast.intValue());
      subStringBegin = subStringLast.intValue() + 1;
    }
    
    return response;
  }
  
  /* the return hashtable may be empty! 
   * Hashtabel format (Integer as key | String as data) */
  public static Hashtable nodeMapSpliter(String nodeMap) {
    Hashtable ht = new Hashtable();
    if (nodeMap == null) {
      return ht;
    }
    
    String[] values = ToolBox.split(nodeMap, ';');
    
    for (int i = 0; i < values.length; i++) {
      String[] pair = ToolBox.split(values[i], ',');
      if (pair.length == 2)
        try {
          ht.put(new Integer(Integer.parseInt(pair[0])),
              pair[1]);
        } catch (NumberFormatException e) {
          CldcLogger.warning("Couple (" + pair[0] + "|" + pair[1] + ") ignored" +
              " to make IDNode/placeNum hashtable, src:ToolBox");
        }
    }
    return ht;
  }
  
  public static String buildNodeMapProp(Hashtable nodeMap) {
    StringBuffer buf = new StringBuffer();
    for (Enumeration e = nodeMap.keys(); e.hasMoreElements();) {
      Object i = e.nextElement();
      if (i instanceof Integer) {
        buf.append(((Integer) i).toString() + VALUES_SEP + nodeMap.get(i) +
          PAIRS_SEP);
      }
    }
    return buf.toString();
  }
}
