//$Id: DestC.nc,v 1.3 2005/06/14 18:10:10 gtolle Exp $

/**
 * This component provides a basic set of queries for DestMsg ADTs.
 *
 * @author Gilman Tolle
 */

configuration DestC {
  provides interface Dest;
}
implementation {
  components DestM;

  Dest = DestM;
}
