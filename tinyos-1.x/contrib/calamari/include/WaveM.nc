includes Wave;

module WaveM
{
  provides interface Wave;
  provides interface StdControl;
  
  uses interface Timer;
  uses interface Time;
  uses interface Random;
  uses interface DiagMsg;
}
implementation
{

  uint8_t mapping[MAX_WAVES];
  wave_element_t waves[MAX_WAVES];
  uint8_t numberOfWaves=0;
  bool timerSet = FALSE;
  uint32_t timerStartTime;
  uint16_t timerLength;

  command result_t StdControl.init() {
    uint8_t i;
    for(i=0;i<MAX_WAVES;i++) {
      waves[i].level=-1;
      waves[i].timer=0;
      waves[i].timerBase=8000;
      waves[i].timerMask=0;
    }
    call Random.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }
  
  command result_t StdControl.stop() {
    return SUCCESS;
  }

  int8_t getWaveIndex(uint8_t id) {
    uint8_t i;
    for(i=0;i<numberOfWaves;i++)
      if(mapping[i] == id)
	return i;

    return -1;
  }
  
  command result_t Wave.setTimerParameters(uint8_t id,
					   uint16_t base,
					   uint16_t mask) {
    int8_t index_ = getWaveIndex(id);
    if(index_ == -1)
      return FAIL;
    
    waves[index_].timerBase = base;
    waves[index_].timerMask = mask;
    return SUCCESS;
  }

  command result_t Wave.reset(uint8_t id) {
    int8_t index_ = getWaveIndex(id);
    if(index_ == -1)
      return FAIL;
    
    waves[index_].level=-1;
    waves[index_].timer=0;
    return SUCCESS;
  }

  command result_t Wave.overheard(uint8_t id, uint8_t level) {
    uint32_t currentTime = call Time.getLow32();
    uint32_t diff=0;
    int8_t index_;
    bool flag = FALSE;
    
    atomic {
      index_ = getWaveIndex(id);
      if(index_ == -1) {
	if(numberOfWaves == MAX_WAVES)
	  flag = TRUE;
	else {
	  mapping[numberOfWaves] = id;
	  index_ = numberOfWaves;
	  waves[index_].level = (uint8_t) -1;
	  numberOfWaves++;
	}
      }
    }
    if(flag)
      return FAIL;

    atomic {
      if(waves[index_].level == (uint8_t) -1) {
	// we don't have a level yet
	// set level and timer to rebroadcast
	waves[index_].level = level + 1;
	waves[index_].timer = waves[index_].timerBase +
	  (waves[index_].timerMask & call Random.rand());
	if(!timerSet) {
	  /*if(call DiagMsg.record() == SUCCESS) {
	    call DiagMsg.str("init");
	    call DiagMsg.uint16(TOS_LOCAL_ADDRESS);
	    call DiagMsg.uint16(waves[index_].level);
	    call DiagMsg.uint16(waves[index_].timer);
	    call DiagMsg.send();
	    }*/
	  timerSet = TRUE;
	  timerStartTime = call Time.getLow32();
	  timerLength = waves[index_].timer;
	  call Timer.start(TIMER_ONE_SHOT,waves[index_].timer);
	} else {
	  if(currentTime > timerStartTime)
	    diff = currentTime - timerStartTime;
	  waves[index_].timer += diff;
	}
      } else {
	// if we hear a lower level and have a send pending, then reset timer
	if(waves[index_].timer > 0 && waves[index_].level > level) {
	  if(currentTime > timerStartTime)
	    diff = currentTime - timerStartTime;
	  waves[index_].timer = waves[index_].timerBase +
	    (waves[index_].timerMask & call Random.rand()) + diff;
	  /*  if(call DiagMsg.record() == SUCCESS) {
	    call DiagMsg.str("overheard");
	    call DiagMsg.uint16(TOS_LOCAL_ADDRESS);
	    call DiagMsg.uint16(level);
	    call DiagMsg.uint16(waves[index_].level);
	    call DiagMsg.uint16(waves[index_].timer);
	    call DiagMsg.send();
	    }*/
	}
      }
    }
    return SUCCESS;
  }

  command uint8_t Wave.getLevel(uint8_t id) {
    int8_t index_ = getWaveIndex(id);
    if(index_ == -1)
      return FAIL;
    return waves[index_].level;
  }

  command void Wave.setLevel(uint8_t id, uint8_t level) {
    int8_t index_;
    bool flag = FALSE;
    
    atomic {
      index_ = getWaveIndex(id);
      if(index_ == -1) {
	if(numberOfWaves == MAX_WAVES)
	  flag = TRUE;
	else {
	  mapping[numberOfWaves] = id;
	  index_ = numberOfWaves;
	  waves[index_].level = level;
	  numberOfWaves++;
	}
      } else {
	waves[index_].level = level;
      }
    }
  }
    
  event result_t Timer.fired() {
    uint8_t i;
    int8_t nextTimerOwner=-1;
    uint16_t min=65535u;

    atomic {
      for(i=0;i<numberOfWaves;i++) {
	if(waves[i].timer > 0) {
	  if(waves[i].timer <= timerLength) {
	    waves[i].timer = 0;
	    signal Wave.fired(mapping[i],waves[i].level);
	if(call DiagMsg.record() == SUCCESS) {
	  call DiagMsg.str("expire");
	  call DiagMsg.uint16(TOS_LOCAL_ADDRESS);
	  call DiagMsg.uint16(waves[i].level);
	  call DiagMsg.send();
	}
	  } else {
	    waves[i].timer -= timerLength;
	    if(waves[i].timer <= min)
	      nextTimerOwner = i;
	  }
	}
      }
      if(nextTimerOwner != -1) {
	timerStartTime = call Time.getLow32();
	timerLength = waves[nextTimerOwner].timer;
	call Timer.start(TIMER_ONE_SHOT,waves[nextTimerOwner].timer);
      } else
	timerSet = FALSE;
    }
    return SUCCESS;
  }

  default event result_t Wave.fired(uint8_t id,uint8_t level) {
    return SUCCESS;
  }
}
