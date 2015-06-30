max_value self_forward(value x)
{
  struct obj *obj;

  if (ATOMP(x) || INTEGERP(x) || !x)
    return (max_value)x;

  obj = x;
  if (obj->forwarded)
    return obj->size;

  save_copy_and_scan(&self_layout, obj, obj->size);
}

instruction *self_copy_code_header(u8 *newobj, struct code *code)
{
  struct code *newcode = (struct code *)newobj;

  newcode->nb_locals = code->nb_locals;
  newcode->stkdepth = code->stkdepth;
  newcode->help = self_forward(code->help);
  newcode->filename = self_forward(code->filename);
  newcode->varname = self_forward(code->varname);
  newcode->nargs = code->nargs;

  return newcode->ins;
}

