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
 
module OPstartradioM {
 
  provides {
    interface MateBytecode;
  }
 
  uses {
    interface Leds;
    interface StdControl as RadioControl;
  }
}
 
implementation {


  enum {
  	START_MAX_RETRIES = 3
  };

  uint8_t retries = 0;

  ////////////// MateBytecode Commands //////////////
  /**
   * Turn off radio using StdControl.
   */
  command result_t MateBytecode.execute(uint8_t instruction,
					MateContext* context)
  {
    // start the radio
    if (call RadioControl.start() != SUCCESS) {
      if (retries < START_MAX_RETRIES) {
        // reschedule
      	retries++;
        context->pc--;
      }
      else {
        // give up - might already be started
        retries = 0;
      }
    }

    return SUCCESS;
  }


  /**
   *
   */
  command uint8_t MateBytecode.byteLength() {
    return 1;
  }
   
}
