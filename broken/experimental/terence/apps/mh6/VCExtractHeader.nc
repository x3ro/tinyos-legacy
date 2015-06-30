includes AM;
interface VCExtractHeader {
  command void extractHeader(uint8_t *data, uint16_t *source, int8_t *seqnum);
  command uint8_t *extractData(TOS_MsgPtr msg);
}
