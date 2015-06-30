//$Id: GroupManager.nc,v 1.4 2005/07/16 01:27:15 gtolle Exp $

interface GroupManager {

  command bool isMember(uint16_t groupID);
  command result_t joinGroup(uint16_t groupID, uint16_t timeout);
  command result_t leaveGroup(uint16_t groupID);

  command bool isForwarder(uint16_t groupID);
  command result_t joinForward(uint16_t groupID, uint16_t timeout);
  command result_t leaveForward(uint16_t groupID);
}
