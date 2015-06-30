interface BTLinkController
{
     command void Init(struct BTLinkController* lc, amaddr_t am, struct LMP* lmp);
     command void Initialize(struct BTLinkController* lc);
     command struct BTPacket* send(struct BTLinkController* lc, int pktSize);
     command void recv(struct BTLinkController* lc, struct BTPacket* p);
     command void setAmAddr(struct BTLinkController* lc, amaddr_t am_addr);
     command void transmitted(struct BTLinkController* lc);
}
