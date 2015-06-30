import java.util.*;

public class Watchable implements Comparable, Cloneable {
  private String name;
  private int key;
  private int length;
  private String type;

  private ArrayList history = new ArrayList();
    
  public Watchable(String n, int k, int l, String t) {
    name = n; key = k; length = l; type = t;
  }

  public String getName() {
    return name;
  }

  public int getKey() {
    return key;
  }

  public int getLength() {
    return length;
  }

  public String getType() {
    return type;
  }

  public int compareTo(Object o) {
    Watchable w = (Watchable) o;
    return name.compareTo(w.getName());
  }

  public String toString() {
    return name;
  }

  public int hashCode() {
    return name.hashCode();
  }
  
  public boolean equals(Object o) {
    if (!(o instanceof Watchable))
      return false;

    Watchable w = (Watchable) o;
    return name.equals(w.getName());
  }

  public Object clone() {
    Watchable w = new Watchable(name, key, length, type);
    return w;
  }

  public void newData(ArrayList bytes) {
    
  }
}
