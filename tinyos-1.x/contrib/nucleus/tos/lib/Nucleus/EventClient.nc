//$Id: EventClient.nc,v 1.3 2005/06/14 18:10:10 gtolle Exp $

interface EventClient
{
  event result_t fired(uint8_t length, void *buf);
  event result_t logged(uint8_t length, uint8_t class, void *buf);
}

