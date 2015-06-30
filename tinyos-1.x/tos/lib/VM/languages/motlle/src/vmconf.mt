/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
any rbytecode_mwritec, rbytecode_mwriteg, rbytecode_mwritel, rbytecode_mwritel3, rbytecode_mwritedc, rbytecode_mwritedg, rbytecode_mwritedl, rbytecode_mwritedl3, rbytecode_mclearl, rbytecode_mreadc, rbytecode_mreadg, rbytecode_mreadl, rbytecode_mreadc3, rbytecode_mreadl3, rbytecode_mset, rbytecode_mref, rbytecode_mexec4, rbytecode_mexecg4, rbytecode_mexecprim6, rbytecode_mclosure, rbytecode_mreturn, rbytecode_halt, rbytecode_mhandler, rbytecode_mba3, rbytecode_mbf3, rbytecode_mbt3, rbytecode_mbfp3, rbytecode_mbtp3, rbytecode_mscheck4, rbytecode_mvcheck4, rbytecode_mcst, rbytecode_mint3, rbytecode_mundefined, rbytecode_mpop, rbytecode_mexitn, rbytecode_mbitxor, rbytecode_mbitor, rbytecode_mbitnot, rbytecode_mbitand, rbytecode_mshiftright, rbytecode_mshiftleft, rbytecode_mnegate, rbytecode_madd, rbytecode_msub, rbytecode_mmultiply, rbytecode_mdivide, rbytecode_mremainder, rbytecode_meq, rbytecode_mne, rbytecode_mlt, rbytecode_mle, rbytecode_mgt, rbytecode_mge, rbytecode_mnot;

any set_bytecodes!(gstate)
{
  string bytecodemap = make_string(256);

  any nbit(from, to, n)
  {
    for (any i = 0; i < 1 << n; i++)
      bytecodemap[from + i] = to + i;
  }

  bytecodemap[bytecode_OPmwritec] = rbytecode_mwritec;
  bytecodemap[bytecode_OPmwriteg] = rbytecode_mwriteg;
  bytecodemap[bytecode_OPmwritel] = rbytecode_mwritel;
  nbit(bytecode_OPmwritel3, rbytecode_mwritel3, 3);
  bytecodemap[bytecode_OPmwritedc] = rbytecode_mwritedc;
  bytecodemap[bytecode_OPmwritedg] = rbytecode_mwritedg;
  bytecodemap[bytecode_OPmwritedl] = rbytecode_mwritedl;
  nbit(bytecode_OPmwritedl3, rbytecode_mwritedl3, 3);
  bytecodemap[bytecode_OPmclearl] = rbytecode_mclearl;

  bytecodemap[bytecode_OPmreadc] = rbytecode_mreadc;
  bytecodemap[bytecode_OPmreadg] = rbytecode_mreadg;
  bytecodemap[bytecode_OPmreadl] = rbytecode_mreadl;
  nbit(bytecode_OPmreadc3, rbytecode_mreadc3, 3);
  nbit(bytecode_OPmreadl3, rbytecode_mreadl3, 3);

  bytecodemap[bytecode_OPmset] = rbytecode_mset;
  bytecodemap[bytecode_OPmref] = rbytecode_mref;

  nbit(bytecode_OPmexec4, rbytecode_mexec4, 4);
  nbit(bytecode_OPmexecg4, rbytecode_mexecg4, 4);
  nbit(bytecode_OPmexecprim6, rbytecode_mexecprim6, 6);
  bytecodemap[bytecode_OPmclosure] = rbytecode_mclosure;
  bytecodemap[bytecode_OPmreturn] = rbytecode_mreturn;
  bytecodemap[bytecode_OPhalt] = rbytecode_halt;
  bytecodemap[bytecode_OPmhandler] = rbytecode_mhandler;

  nbit(bytecode_OPmba3, rbytecode_mba3, 3);
  nbit(bytecode_OPmbf3, rbytecode_mbf3, 3);
  nbit(bytecode_OPmbt3, rbytecode_mbt3, 3);
  if (!null?(rbytecode_mbfp3))
    {
      // motlle vms don't have mb[ft]p3
      nbit(bytecode_OPmbfp3, rbytecode_mbfp3, 3);
      nbit(bytecode_OPmbtp3, rbytecode_mbtp3, 3);
    }

  nbit(bytecode_OPmscheck4, rbytecode_mscheck4, 4);
  nbit(bytecode_OPmvcheck4, rbytecode_mvcheck4, 4);

  bytecodemap[bytecode_OPmcst] = rbytecode_mcst;
  nbit(bytecode_OPmint3, rbytecode_mint3, 3);
  bytecodemap[bytecode_OPmundefined] = rbytecode_mundefined;
  bytecodemap[bytecode_OPmpop] = rbytecode_mpop;
  bytecodemap[bytecode_OPmexitn] = rbytecode_mexitn;

  bytecodemap[bytecode_OPmbitxor] = rbytecode_mbitxor;
  bytecodemap[bytecode_OPmbitor] = rbytecode_mbitor;
  bytecodemap[bytecode_OPmbitnot] = rbytecode_mbitnot;
  bytecodemap[bytecode_OPmbitand] = rbytecode_mbitand;
  bytecodemap[bytecode_OPmshiftright] = rbytecode_mshiftright;
  bytecodemap[bytecode_OPmshiftleft] = rbytecode_mshiftleft;

  bytecodemap[bytecode_OPmnegate] = rbytecode_mnegate;
  bytecodemap[bytecode_OPmadd] = rbytecode_madd;
  bytecodemap[bytecode_OPmsub] = rbytecode_msub;
  bytecodemap[bytecode_OPmmultiply] = rbytecode_mmultiply;
  bytecodemap[bytecode_OPmdivide] = rbytecode_mdivide;
  bytecodemap[bytecode_OPmremainder] = rbytecode_mremainder;

  bytecodemap[bytecode_OPmeq] = rbytecode_meq;
  bytecodemap[bytecode_OPmne] = rbytecode_mne;
  bytecodemap[bytecode_OPmlt] = rbytecode_mlt;
  bytecodemap[bytecode_OPmle] = rbytecode_mle;
  bytecodemap[bytecode_OPmgt] = rbytecode_mgt;
  bytecodemap[bytecode_OPmge] = rbytecode_mge;

  bytecodemap[bytecode_OPmnot] = rbytecode_mnot;

  set_gstate_bytecodes!(gstate, bytecodemap);
}

any prims = null, primcount = 0;

any moteprim(name, index, nargs, retval)
{
  prims = list(name, index, nargs) . prims;
  primcount++;
}

any set_primops!(gstate)
{
  any nargsvec = make_vector(primcount);

  lforeach(fn (prim)
    {
      any name, index, nargs, gvar_index;

      (name index nargs) = prim;
      nargsvec[index] = nargs;
      gvar_index = global_add(gstate, name);
      global_set!(gstate, gvar_index, make_primitive(index));
      module_vset!(gstate, gvar_index, "system");
    }, prims);
  set_gstate_primops!(gstate, nargsvec);
}

any csts = null, cstcount = 0;

any motecst(name, val)
{
  csts = list(name, val) . csts;
  cstcount++;
}

any set_constants!(gstate)
{
  lforeach(fn (cst)
    {
      any name, val, gvar_index;

      (name val) = cst;
      gvar_index = global_add(gstate, name);
      global_set!(gstate, gvar_index, val);
      module_vset!(gstate, gvar_index, "system");
    }, csts);
}

any handlers = null, handlercount = 0;

any motehandler(name, index)
{
  handlers = (name . index) . handlers;
  handlercount++;
}

any set_handlers!(mstate)
{
  any handlervars = "", vhandlers = make_vector(handlercount);
  any define_mate_handler(handler)
    remote_save(mstate, string_compile(mstate[0], string_append("any ", string_append(handler, " = 0;")), false))[1];
  
  lforeach(fn (handler) vhandlers[cdr(handler)] = car(handler), handlers);
  for (any i = 0; i < handlercount; i++)
    handlervars = string_append(handlervars, define_mate_handler(vhandlers[i]));

  return handlervars;
}
