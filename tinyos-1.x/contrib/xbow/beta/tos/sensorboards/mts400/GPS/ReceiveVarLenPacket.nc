interface ReceiveVarLenPacket
{

  event uint8_t* receive(uint8_t* receivedBuffer, uint8_t bufferLength);

}
