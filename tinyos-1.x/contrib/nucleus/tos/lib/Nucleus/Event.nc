//$Id: Event.nc,v 1.3 2005/06/14 18:10:10 gtolle Exp $

interface Event<t> {
  event result_t fire(t* buf);
  event result_t log(uint8_t class, t *buf);
}
