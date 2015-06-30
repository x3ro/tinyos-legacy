includes Mate;
includes Motlle;
interface MotlleTypes {
  command mtype user_type(mvalue x);
  command mtype internal_type(mvalue x);

  command bool codep(mvalue x);
  command bool nullp(mvalue x);
  command bool stringp(mvalue x);
  command bool vectorp(mvalue x);
  command bool pairp(mvalue x);
  command bool closurep(mvalue x);
  command bool intp(mvalue x);
  command bool realp(mvalue x);
  command bool functionp(mvalue x);
  command bool primitivep(mvalue x);
  command bool listp(mvalue x);

  command vcode code(mvalue x);
  command vstring string(mvalue x);
  command vvector vector(mvalue x);
  command vpair pair(mvalue x);
  command vclosure closure(mvalue x);
  command vint intv(mvalue x);
  command vreal real(mvalue x);
  command vprimitive primitive(mvalue x);

  command mvalue make_code(vcode x);
  command mvalue make_string(vstring x);
  command mvalue make_vector(vvector x);
  command mvalue make_pair(vpair x);
  command mvalue make_closure(vclosure x);
  command mvalue make_int(vint x);
  command mvalue make_real(vreal x);
  command mvalue make_primitive(vprimitive x);

  command vstring alloc_string(msize size);
  command vvector alloc_vector(msize nentries);
  command vpair alloc_list(mvalue car, mvalue cdr);

  command mvalue nil();
  command bool truep(mvalue x);
  command mvalue make_bool(bool x);
  command int8_t primitive_args(vprimitive x);
  command bool primitive_retval(vprimitive x);
  command msize vector_length(vvector v);
  command msize string_length(vstring s);

  // Utility tests, helpful for implementing arithmetic stuff
  command bool int_intp(mvalue x, mvalue y);
  command bool real_intp(mvalue x, mvalue y);
  command bool real_realp(mvalue x, mvalue y);

  command bool numberp(mvalue x);
  /* Returns: TRUE if x is an int or real */
  command bool promotep(mvalue x, mvalue y);
  /* Returns: TRUE if at least one of x, y is a real, and the other 
       is a real or int. Used for operations that implicitly promote
       int arguments to real when the other argument is a real. */
  command vreal number(mvalue x);
  /* Returns: number x (int or real) as a real */
}
