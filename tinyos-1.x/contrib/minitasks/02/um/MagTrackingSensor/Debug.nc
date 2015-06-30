interface Debug
{
  command void init();
  command void setAddr(uint16_t address);
  command void setTimeout(uint32_t timeout);
  command void sendNow();

  command result_t dbg8(uint8_t x);
  command result_t dbg16(uint16_t x);
  command result_t dbg32(uint32_t x);
  command result_t dbgString(char *s);
}
