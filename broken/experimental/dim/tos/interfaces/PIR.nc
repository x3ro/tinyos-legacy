/*
 * A Protocol-Independent Routing(PIR) shim. We use bare TOS messages
 * to let the application access the routing layer.
 */
interface PIR {
  command result_t send(uint16_t saddr, Coord dest, uint8_t len, uint8_t *msg);
  event result_t arrive(uint16_t saddr, Coord coord, uint8_t len, uint8_t *msg);
}
/*
 * For now, they are just a frame within which the
 * GenericComm commands/events are embedded. 
 */
