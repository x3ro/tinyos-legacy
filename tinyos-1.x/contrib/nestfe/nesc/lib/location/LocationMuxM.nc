includes Registry;
includes Rpc;
includes DetectionEvent;
includes LocationMux;

  /*****
   * This module is an attribute multiplexer. In other words, multiple
   * attributes (of the same type muxAttr_t) can be wired to the Input
   * interface of this module.  This module provides a "virtual"
   * attribute of the same type, which is multiplexed over the input
   * attributes through the user-specified "channel".  The virtual
   * output attribute can be accessed through Registry using the
   * user-specified parameter name "Output".
   *
   * This module is useful, for example, to have many sources of a
   * sensor value or location, but a single interface for switching
   * between them.
   *
   * Note: this should be a generic module, but currently is not
   *  because:
   * 1.  generic modules cannot _provide_ Attribute interfaces because
   * Registry cannot wire to them.  
   * 2.  we do not how to parse abstract type parameters yet for
   * generation of the RegistryC file
   * Until then, To change this to something besides location, do a
   * string replace between:  
   *    location_t -> your_t
   *    Location -> your name
   *    DEFAULT_LOCATION_CHANNEL -> your var
   * After then, make this a generic module with the 3 items above as
   * parameters. 
   *****/

module LocationMuxM {
  provides{ 
    interface StdControl;

    interface Attribute<location_t> as Location @registry("Location");
    interface AttrBackend<location_t> as LocationBackend;

    command void select(uint8_t channel) @rpc();
    command uint8_t getChannel() @rpc();
  }
  uses{
    interface Attribute<location_t> as Input[uint8_t channel];
    interface AttrBackend<location_t> as InputBackend[uint8_t channel];
  }
}
implementation {

  uint8_t channel;

  /*****
   * StdControl
   *****/

  command result_t StdControl.init() {
    channel = DEFAULT_LOCATION_CHANNEL;
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }


  /*****
   * mux interface
   *****/

  command void select(uint8_t newChannel){
    channel = newChannel;
    //UH-OH!  What if the new channel is invalid?  Now we are sending
    //an updated event for an invalid value?
    signal Location.updated(call Input.get[channel]());
  }

  command uint8_t getChannel(){
    return channel;
  }


  /*****
   * Translation between input and output channels
   *****/

  command bool Location.valid(){
    return call Input.valid[channel]();
  }
  command location_t Location.get(){
    return call Input.get[channel]();
  }
  command result_t Location.set(location_t val){
    return call Input.set[channel](val);
  }
  command bool Location.update(){
    return call Input.update[channel]();
  }

  event void Input.updated[uint8_t p_channel](location_t val)  {
    if ( channel == p_channel ){
      signal Location.updated(val);
      signal LocationBackend.updated(call InputBackend.get[channel]());
    }
  }

  default event void Location.updated(location_t val)  {
  }


  command uint8_t LocationBackend.size() {
    return call InputBackend.size[channel]();
  }
  command const void* LocationBackend.get() {
    return call InputBackend.get[channel]();
  } 
  command result_t LocationBackend.set(const void* val) {
    return call InputBackend.set[channel](val);
  }
  command result_t LocationBackend.update() {
    return call InputBackend.update[channel]();
  }
  default event void LocationBackend.updated(const void* newval) {
  }


  /*****
   * default input channels
   *****/

  default command bool Input.valid[uint8_t p_channel](){
    return FALSE;
  }
  default command location_t Input.get[uint8_t p_channel](){
    location_t val;
    return val;
  }
  default command result_t Input.set[uint8_t p_channel](location_t val){
    return FAIL;
  }
  default command bool Input.update[uint8_t p_channel](){
    return FALSE;
  }


  default command uint8_t InputBackend.size[uint8_t p_channel]() {
    return 0;
  }
  default command const void* InputBackend.get[uint8_t p_channel]() {
    return NULL;
  } 
  default command result_t InputBackend.set[uint8_t p_channel](const void* val) {
    return FAIL;
  }
  default command result_t InputBackend.update[uint8_t p_channel]() {
    return FAIL;
  }
  event void InputBackend.updated[uint8_t p_channel](const void* newval) {
  }

}

