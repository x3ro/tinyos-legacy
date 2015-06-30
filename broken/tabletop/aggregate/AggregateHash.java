import java.awt.*;
import java.awt.geom.*;
import java.util.*;

public class AggregateHash extends Hashtable
{
  boolean get_boolean( Object key ) { return getBoolean(key).booleanValue(); }
  double  get_double( Object key ) { return getDouble(key).doubleValue(); }
  int     get_int( Object key ) { return getInteger(key).intValue(); }

  void put_boolean( Object key, boolean x ) { put( key, new Boolean(x) ); }
  void put_double( Object key, double x ) { put( key, new Double(x) ); }
  void put_int( Object key, int x ) { put( key, new Integer(x) ); }

  boolean toggle_boolean( Object key )
  {
    boolean b = !get_boolean(key); 
    put( key, new Boolean(b) );
    return b;
  }

  Boolean            getBoolean( Object key ) { return (Boolean)get(key); }
  Color              getColor( Object key ) { return (Color)get(key); }
  Double             getDouble( Object key ) { return (Double)get(key); }
  Integer            getInteger( Object key ) { return (Integer)get(key); }
  Rectangle2D.Double getRectangle2D_Double( Object key ) { return (Rectangle2D.Double)get(key); }
  Rectangle2D.Double getRect( Object key ) { return (Rectangle2D.Double)get(key); }
  String             getString( Object key ) { return (String)get(key); }
}

