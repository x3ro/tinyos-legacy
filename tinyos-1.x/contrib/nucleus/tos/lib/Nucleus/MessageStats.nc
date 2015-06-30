//$Id: MessageStats.nc,v 1.2 2005/06/14 18:10:10 gtolle Exp $

interface MessageStats {
  async event result_t pass(uint16_t bytes);
  async event result_t fail(uint8_t errorCode);
}
