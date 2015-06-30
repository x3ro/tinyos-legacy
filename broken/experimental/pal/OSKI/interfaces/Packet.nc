interface Packet {
  command void clear(TOSMsg* msg);
  command uint8_t payloadLength(TOSMsg* msg);
  command uint8_t maxPayloadLength();
  command void* getPayload(TOSMsg* msg, uint8_t* len);
}



