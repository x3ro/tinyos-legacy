package straw;

import java.io.*;

class Counter {

  String nm;
  short no;

  Counter(String aNm) {
    nm = aNm;
  }
  
  short get() {
    try {
      FileReader fr = new FileReader(nm);
      BufferedReader br = new BufferedReader(fr);

      no = Short.parseShort(br.readLine());
      
      br.close();
      fr.close();
    } catch (IOException e) {
      no = 1;
    }
    return no;
  }
  
  int set(short newNo) {
    try {
      FileOutputStream fos = new FileOutputStream(nm);
      PrintWriter pr = new PrintWriter(fos);
 
      no = newNo;
      pr.println("" + no);
      
      pr.close();
      fos.close();
    } catch (IOException e) {
      System.out.println("Exception: Counter.set"
        + " - while storing number to " + nm);
      return 1;
    }
    return 0;
  }

  int incr() {
    ++no;
    return set(no);
  }

  int reset() {
    return set((short)1);
  }
  
};

