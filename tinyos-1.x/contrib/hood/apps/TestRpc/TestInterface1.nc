interface TestInterface1 
{
  command void testCommand1();
  command result_t testCommand3(uint8_t something);
  command result_t* testCommand4(uint8_t something, uint16_t* data);
  command RpcCommandMsg testCommand5(RpcCommandMsg data);
  command RpcCommandMsg* testCommand6(RpcCommandMsg* data);
  command void testCommand7(RpcCommandMsg data);
  command RpcCommandMsg testCommand8();
}
