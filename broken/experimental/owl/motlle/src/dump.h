#ifndef DUMP_H
#define DUMP_H

struct remote_state
{
  struct obj o;
  struct global_state *gstate;
  struct vector *globals_used;
  value remote_globals_length;
};

struct remote_state *alloc_remote_state(struct global_state *gstate);

void save_copy_and_scan(struct object_layout *layout, struct obj *obj);

bool remote_save(block_t region, struct remote_state *rstate, value x, 
		 u8 **save_mem, uvalue *globals_offset, uvalue *save_size);
/* Effects: Saves value x, created for global state rstate->gstate,
     to memory area *save_mem (allocated in region) for transmission to
     remote machine with state rstate (updated as a result of remote_save)
   Returns: TRUE if successful, FALSE for error
     *save_mem points to the saved memory area
     *save_size is the number of bytes of *save_mem used to save x
     *globals_offset is the offset of the new global variables array (which is
     guaranteed to be the last object in *save_mem)
     (this is the format expected by REQ_LOAD in smain.c)
*/

#endif
