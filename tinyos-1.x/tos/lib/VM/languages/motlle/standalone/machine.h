#ifndef MACHINE_H
#define MACHINE_H

struct machine_specification	/* Is a record (vector) */
{
  struct obj o;
  value library_installer;	/* a function */
  value eval_start, eval_end;	/* functions */
  struct extptr *c_machine_specification;
};

typedef unsigned long long max_value; /* The largest possible word rep
					 we will deal with */

struct object_layout
{
  size_t word_size;		/* in bytes (<= sizeof(max_value)) */
  size_t alignment;
  size_t code_header_length;
  bool big_endian;
  max_value (*forward)(value x);
  void (*write_header)(u8 *to, max_value type, max_value flags, max_value size);
  void (*copy_code_header)(u8 *newobj, struct code *code);
  instruction *bytecodes;
};

struct c_machine_specification
{
  struct primitive_ext **primops;
  uvalue primop_count;
  void (**globals_initialiser)(void);
  uvalue initialiser_count;
  struct object_layout layout;
};

#define C_MACHINE_SPECIFICATION(ms) \
  ((struct c_machine_specification *)(ms)->c_machine_specification->external)

#endif
