includes bt;


/** 
 * Link manager protocol.
 * 
 * <p>The pink LMP boxes in Blueware. There are eight of these. They
 * are stored in the baseband struct of BTBasebandM.nc.</p>
 *
 * <p>When calling a function here, we pass the struct LMP from BTBaseband, as 
 */
interface BTLMP
{
     command void Init(struct LMP* lmp, bool master, amaddr_t am);
     command void dropped(struct LMP* lmp, struct BTPacket* p, bool bFrmQue);

     command struct BTPacket* send(struct LMP* lmp, int pktSize);
     command void recvd(struct LMP* lmp, struct BTPacket* p, struct BTPacket* recvdPkt);
     command void recv (struct LMP* lmp, struct BTPacket* p);
     command void sendLMPCommand2(struct LMP* lmp, enum lmp_opcode opcode, unsigned int arg1, unsigned int arg2);
     command void handle(struct LMP* lmp);
     command void linkDestroyed(struct LMP* lmp, bool bMaster);
     command void linkEstablished(struct LMP* lmp, bool bMaster);
     command void roleChanged(struct LMP* lmp, bool bMaster);
     command void transmitted(struct LMP* lmp, struct BTPacket* p);
}
