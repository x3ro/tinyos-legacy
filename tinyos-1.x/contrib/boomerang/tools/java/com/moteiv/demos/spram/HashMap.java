package com.moteiv.demos.spram;

import java.util.Iterator;
import java.util.Vector;

public class HashMap extends java.util.HashMap
{
  Vector listeners = new Vector();

  public HashMap getHash( Object key ) {
    return (HashMap)(super.get(key));
  }

  public String getStr( Object key ) {
    return (String)(super.get(key));
  }

  public String getStr( Object key, String defaultValue ) {
    String value = getStr(key);
    return value == null ? defaultValue : value;
  }

  public int getInt( Object key ) {
    return getInt( key, 0 );
  }

  public int getInt( Object key, int defaultValue ) {
    String value = getStr(key);
    return value == null ? defaultValue : Integer.parseInt(value);
  }

  public double getDouble( Object key ) {
    return getDouble( key, 0.0 );
  }

  public double getDouble( Object key, double defaultValue ) {
    String value = getStr(key);
    return value == null ? defaultValue : Double.parseDouble(value);
  }

  public boolean getBool( Object key ) {
    return getBool( key, false );
  }

  public boolean getBool( Object key, boolean defaultValue ) {
    String value = getStr(key);
    return value == null ? defaultValue : value.matches("(?i)yes|true|1");
  }

  public void addListener( HashMapListener l ) {
    if( !listeners.contains(l) )
      listeners.add(l);
  }

  public Object put( Object key, Object val ) {
    Object oldval = super.put(key,val);
    
    Iterator i = listeners.iterator();
    while( i.hasNext() ) {
      HashMapListener l = (HashMapListener)i.next();
      l.putEvent( this, key, oldval );
    }

    return oldval;
  }
}

