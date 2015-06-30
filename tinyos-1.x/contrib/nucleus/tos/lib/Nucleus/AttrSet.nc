//$Id: AttrSet.nc,v 1.4 2005/06/14 18:10:10 gtolle Exp $

interface AttrSet<t> {
  command result_t set(t* buf);
  event result_t setDone(t* buf);
}
