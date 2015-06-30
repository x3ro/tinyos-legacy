//$Id: AnyEvent.nc,v 1.3 2005/06/14 18:10:09 gtolle Exp $

interface AnyEvent {
  event result_t fire(uint8_t length, void* buf);
  event result_t log(uint8_t length, uint8_t class, void* buf);
}
