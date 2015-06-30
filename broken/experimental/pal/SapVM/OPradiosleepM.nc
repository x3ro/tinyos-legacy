/*
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT 
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED 
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY 
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE 
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * 
 */

/**
 * @author Mark Kranz
 */
 
module OPradiosleepM {
 
  provides {
    interface MateBytecode;
  }
 
  uses {
    interface Leds;
    interface StdControl as RadioControl;
    interface MateStacks as Stacks;
    interface TimerMilli as SleepTimer;
    interface MateEngineStatus as EngineStatus;
    interface MateTypes as Types;
    interface MateContextSynch as Synch;
    
    event result_t radioOn();
    interface StdControl as VirusControl;
  }
}
 
implementation {


	enum {
		START_MAX_RETRIES = 3
	};

  MateContext* sleepContext = NULL;
	uint8_t retries;

  ////////////// MateBytecode Commands //////////////
  /**
   * Turn off radio using StdControl.
   */
  command result_t MateBytecode.execute(uint8_t instruction,
					MateContext* context)
  {
    uint32_t time;
    
    // time to sleep in seconds
    MateStackVariable* arg = call Stacks.popOperand(context);
   
    if (!call Types.checkTypes(context, arg, MATE_TYPE_INTEGER))
      return FAIL;
      
    // do NOT sleep if already asleep
    if (sleepContext != NULL)
    	return SUCCESS;
     
    // halt the radio
    if (call RadioControl.stop() != SUCCESS) {
      // fail
    }
    else {
      // use 32 bit variable to prevent overflow
      time = (uint32_t)arg->value.var;
      time = ((uint32_t)(1024))*time;
			
			// stop virus first
			call VirusControl.stop();
    	call VirusControl.init();

      call SleepTimer.setOneShot(time);
      retries = 0;
      
      
      // Does NOT block context while radio is asleep
      /*
      sleepContext = context;
	  	context->state = MATE_STATE_BLOCKED;
	  	call Synch.yieldContext(context);
	  	*/
    }
    
    return SUCCESS;
  }

  /**
   * Wakes up the radio on timer fire
   */
  event result_t SleepTimer.fired() {
    if (call RadioControl.start() != SUCCESS) {
      // retry on failure
      if (retries < START_MAX_RETRIES) { 
      	retries++;
      	// short wait before retry
      	call SleepTimer.setOneShot(10);
      }
      else {
      	// DEBUG: let us know when radio has failed to start
      	// should only happen if radio is already on
      	// or some form of coincidence?
      	call Leds.set(7);
      }      
    }
    // Currently does NOT block context
    //if (sleepContext != NULL)
    //	call Synch.resumeContext(sleepContext, sleepContext);
    
    sleepContext = NULL;
    // give a fake sendDone event to generic comm clients
    // who may have failed a send while the radio was asleep
    // and is waiting for radio
    signal radioOn();
    
    // restart virus
    call VirusControl.start();
    
    return SUCCESS;
  }

  /**
   *
   */
  command uint8_t MateBytecode.byteLength() {
    return 1;
  }
  
  event void EngineStatus.rebooted() {
    atomic {
      sleepContext = NULL;
    }
  }  
}
