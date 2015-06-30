interface MinTransDBPacket {
  command void sendDbMsg(uint8_t decision, uint8_t parent);
  command void storeBestParentInfo(uint8_t bestParent, uint16_t bestParentLinkCost, 
				   uint16_t bestParentCost, uint8_t bestParentSendEst, 
				   uint8_t bestParentReceiveEst);
  command void storeOldParentInfo(uint8_t oldParent, uint16_t oldParentLinkCost, 
				  uint16_t oldParentCost, uint8_t oldParentSendEst, 
				  uint8_t oldParentReceiveEst);
}
