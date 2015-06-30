/**
 * The Power Arbiter
 *
 * A centralized component for managing the power
 * of various components.  Registers the use of the
 * components, and turns them on when a component is in use,
 * and subsequently turning them off when the component
 * is not in use.
 *
 * @author Stan Rost 
 **/
includes PowerArbiter;

module PowerArbiterM {
  uses {
    interface StdControl[uint8_t id];
  }
  provides {
    interface StdControl as StdControlInt;
    interface PowerArbiter[uint8_t id];
  }
}
implementation {

  enum {
    NUM_USERS = uniqueCount("PowerArbiter"),
    NUM_MASK_BITS = (NUM_USERS * PWR_RESOURCE_MAX),
    NUM_MASK_BYTES = ((NUM_MASK_BITS + 7) / 8)
  };

  uint8_t compMasks[NUM_MASK_BYTES];

  void setBit(uint8_t compId, uint8_t resId) {
    uint16_t bit = (uint16_t)compId * resId;
    
    uint16_t _byte = bit >> 3;
    uint16_t _bit = bit & 0x07;

    compMasks[_byte] |= (1 << _bit);
  }

  void clearBit(uint8_t compId, uint8_t resId) {
    uint16_t bit = (uint16_t)compId * resId;
    
    uint16_t _byte = bit >> 3;
    uint16_t _bit = bit & 0x07;

    compMasks[_byte] &= ~(1 << _bit);
  }

  bool testBit(uint8_t compId, uint8_t resId) {
    uint16_t bit = (uint16_t)compId * resId;
    
    uint16_t _byte = bit >> 3;
    uint16_t _bit = bit & 0x07;

    return (compMasks[_byte] & (1 << _bit)) != 0;
  }

  bool inUse(uint8_t resourceId) {
    uint8_t i;
    bool _inUse = FALSE;

    for (i = 0; i < NUM_USERS; i++) {
      if (testBit(i, resourceId)) {
	_inUse = TRUE;

	break;
      }
    }

    return _inUse;
  }

  default command result_t StdControl.init[uint8_t id]() {

    dbg(DBG_USR1, "PowerArbiter:  initializing default (%u)\n", id);

    return SUCCESS;
  }
  default command result_t StdControl.start[uint8_t id]() {
    dbg(DBG_USR1, "PowerArbiter:  starting default (%u)\n", id);

    return SUCCESS;
  }
  default command result_t StdControl.stop[uint8_t id]() {
    dbg(DBG_USR1, "PowerArbiter:  stopping default (%u)\n", id);

    return SUCCESS;
  }

  command result_t StdControlInt.init() {
    uint16_t i;

    for (i = 0; i < NUM_MASK_BYTES; i++) {
      compMasks[i] = 0;

      if (call StdControl.init[i]() == FAIL)
	return FAIL;
    }

    return SUCCESS;
  }

  command result_t StdControlInt.start() {
    return SUCCESS;
  }

  command result_t StdControlInt.stop() {
    return SUCCESS;
  }

  command result_t PowerArbiter.useResource[uint8_t id](uint8_t resourceID) {
    if (resourceID >= PWR_RESOURCE_MAX ||
	testBit(id, resourceID))
      return FAIL;


    if (!inUse(resourceID))
      // The component is not in use, start it
      call StdControl.start[resourceID]();
    
    setBit(id, resourceID);

    return SUCCESS;
  }

  command result_t PowerArbiter.releaseResource[uint8_t id](uint8_t resourceID) {
    if (resourceID >= PWR_RESOURCE_MAX ||
	!testBit(id, resourceID))
      return FAIL;

    clearBit(id, resourceID);

    if (!inUse(resourceID))
      // The component is no longer in use, stop it
      call StdControl.stop[resourceID]();
    
    return SUCCESS;
  }

}
