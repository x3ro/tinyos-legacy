interface MotlleCode 
{
  command uint8_t read_uint8_t(MateContext *context);
  command int16_t read_offset(MateContext *context, bool sixteen);
  command uint16_t read_local_var(MateContext *context);
  command uint16_t read_closure_var(MateContext *context);
  command uint16_t read_global_var(MateContext *context);
  command mvalue read_value(MateContext *context);
}
