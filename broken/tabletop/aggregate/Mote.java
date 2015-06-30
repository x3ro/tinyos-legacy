
public class Mote
{
  public int id;
  public double xpos;
  public double ypos;
  public LatchData mag;

  public Mote( int _id, double _xpos, double _ypos )
  {
    id = _id;
    xpos = _xpos;
    ypos = _ypos;
    mag = new LatchData();
  }

  public Mote()
  {
    id = 0;
    xpos = 0;
    ypos = 0;
    mag = new LatchData();
  }
}

