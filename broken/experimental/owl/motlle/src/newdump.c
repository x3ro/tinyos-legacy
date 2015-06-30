static u16 insu16(instruction *i)
{
  return i[0] << 8 | i[1];
}

static void wins16(instruction *i, u16 val)
{
  i[0] = val >> 8;
  i[1] = val & 0xff;
}

static void save_forward_cst(struct object_layout *layout, u8 *to, u8 *from)
{
  from -= sizeof(value);
  to -= layout->word_size;

  remote_write(layout, to, save_forward(RINSCST(from)));
}

static max_value converted_code_length(struct object_layout *layout,
				       instruction *start, instruction *end)
{
  max_value remote_len = 0;

  while (start < end)
    {
      instruction ins = *start;

      if (ins == op_closure)
	{
	  start += 2 + sizeof(value) + (u8)start[1];
	  remote_len += 2 + layout->word_size + (u8)start[1];
	}
      else if (ins == op_constant)
	{
	  start += 1 + sizeof(value);
	  remote_len += 1 + layout->word_size;
	}
      else 
	{
	  uvalue isize = ins_size(ins);

	  remote_len += isize;
	  start += isize;
	}
    }
  return remote_len;
}

static void save_copy_and_scan(struct object_layout *layout, struct obj *obj)
{
  max_value remote_header;
  u8 *newobj, *newbody;
  uvalue objsize = obj->size, len;
  const size_t header_size = layout->word_size;

  newobj = dumppos;
  newbody = newobj + header_size;
			
  obj->forwarded = TRUE;
  obj->size = newobj - dumpmem;

  switch (obj->type)
    {
    default:
      assert(0);

    case type_string: case type_null: {
      len = objsize - offsetof(struct gstring, data);
      remote_size = header_size + len;
      dumppos += ALIGN(remote_size, layout->alignment);
      memcpy(newbody, ((struct gstring *)obj)->data, len);
      break;
    }
    case type_function: case type_vector: case type_pair: case itype_variable:
    case type_symbol: case type_table: case type_outputport: {
      struct grecord *rec = (struct grecord *)obj;
      uvalue i;

      len = (objsize - offsetof(struct grecord, data)) / sizeof(value);
      remote_size = header_size + len * layout->word_size;
      dumppos += ALIGN(remote_size, layout->alignment);

      for (i = 0; i < len; i++)
	remote_write(layout, newbody + i * layout->word_size,
		     layout->forward(rec->data[i]));
      break;
    }
    case itype_code: {
      struct code *code = (struct code *)obj;
      instruction *scanins, *insend, *destins;

      destins = layout->copy_code_header(layout, newobj, (struct code *)obj);
      scanins = code->ins;
      insend = code->ins + (objsize - offsetof(struct code, ins));

      len = converted_code_length(scanins, insend);
      remote_size = (u8 *)&destins[len] - newobj;
      dumppos += ALIGN(newsize, layout->alignment);

      /* Walk through, copy and convert code */
      while (scanins < insend)
	{
	  instruction ins = *scanins;

	  if (ins == op_closure)
	    {
	      u8 nvars = (u8)scanins[1];

	      memcpy(destins, scanins, 2 + nvars);
	      scanins += 2 + sizeof(value) + nvars;
	      destins += 2 + layout->word_size + nvars;
	      save_forward_cst(layout, destins, scanins);
	    }
	  else if (ins == op_constant)
	    {
	      *destins = op_constant;
	      scanins += 1 + sizeof(value);
	      destins += 1 + layout->word_size;
	      save_forward_cst(layout, destins, scanins);
	    }
	  else 
	    {
	      uvalue isize;

	      isize = ins_size(ins);
	      memcpy(destins, scanins, isize);
	      switch (ins) /* remap globals */
		{
		case op_execute_global1: case op_execute_global2:
		case op_recall + global_var: case op_assign + global_var:
		case op_define: {
		  u16 gvar = insu16(destins + 1);

		  if (!globals_used[gvar])
		    {
		      globals_used[gvar] = makeint(nglobals_used);
		      new_remote_globals[nglobals_used] =
			layout->forward(globals[gvar]);
		      nglobals_used++;
		    }
		  wins16(destins + 1, intval(globals_used[gvar]));
		  break;
		}
		}
	      destins += isize;
	      scanins += isize;
	    }
	}
      break;
    }
    }
  remote_header = layout->make_header(obj->type, obj->flags, remote_size);
  remote_write(layout, newobj, remote_header);
}
