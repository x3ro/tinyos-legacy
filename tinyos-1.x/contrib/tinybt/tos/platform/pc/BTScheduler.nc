/**
 * Corresponds to some secret scheduler, says Dennis. */

interface BTScheduler
{
     command void Init(struct BTLinkController* lc);
     command enum btmode mode(linkid_t lid);
     command void hold(linkid_t lid, int hold_time, int clkn);
     command int numLinks(enum btmode m);
     command int tillNextActiveLink(int clkn, linkid_t* pLid);
     command void holdExpires(linkid_t lid);
     command void connect(linkid_t lid);
     command void disconnect(linkid_t lid);
     command void recv (struct BTPacket* p);
     command struct BTPacket* schedulePkt(int clkn, int pktSize);

}
