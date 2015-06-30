/* 
 * Copyright (c) 1993-2004 David Gay
 * All rights reserved.
 * 
 * Permission to use, copy, modify, and distribute this software for any
 * purpose, without fee, and without written agreement is hereby granted,
 * provided that the above copyright notice and the following two paragraphs
 * appear in all copies of this software.
 * 
 * IN NO EVENT SHALL DAVID GAY BE LIABLE TO ANY PARTY FOR DIRECT, INDIRECT,
 * SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OF
 * THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF DAVID GAY HAVE BEEN ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * DAVID GAY SPECIFICALLY DISCLAIM ANY WARRANTIES, INCLUDING, BUT NOT LIMITED
 * TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND DAVID
 * GAY HAVE NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES,
 * ENHANCEMENTS, OR MODIFICATIONS.
 */

// Provide a consistent set of operations on sequences: 
// lists, dlists, vectors, strings

// copy, reverse, reverse!, append, append!, map, map!, foreach
// exists?, forall?, reduce, delete, delete!, filter, filter!, find?

// Each operation starts with one of 4 letters (l, d, v, s) to indicate the type
// of sequence on which it operates.

// Predicates terminate in ?
// Operations that mutate the structure end in !
// All comparisons are done with ==

// Several of these operations duplicate existing functions


// Implementation note:
//   the dlist functions rely on the dlist rep for performance

// copy: returns a new sequence with the same contents

any lcopy(lst) 
"l1 -> l2. Returns a copy of l1"
{
  any res, trail;

  if (pair?(lst)) 
    {
      res = car(lst) . null;
      trail = res;
      lst = cdr(lst);
    }
  while (pair?(lst))
    {
      set_cdr!(trail, car(lst) . null);
      trail = cdr(trail);
      lst = cdr(lst);
    }
  return res;
}

any dcopy(d)
"d1 -> d2. Returns a copy of d1"
{
  if (d == null) 
    null;
  else
    {
      any first, l, next, scan;

      // yuck
      first = l = vector(d[0], null, null);
      first[2] = first;

      scan = d[2];
      while (scan != d)
	{
	  next = vector(scan[0], l, null);
	  l[2] = next;
	  l = next;
	  scan = scan[2];
	}
      l[2] = first;
      first[1] = l;
      first;
    }
}

any scopy(s)  
"s1 -> s2. Returns a copy of s1"
  s + ""; // easy ...

any vcopy(v1)
"v1 -> v2. Returns a copy of v1"
{
  any l = vector_length(v1), v2 = make_vector(l);

  while ((l = l - 1) >= 0) v2[l] = v1[l];
  return v2;
}


// length: return length of sequence

any llength(lst)
"l -> n. Returns the length of a list"
{
  any result = 0;

  while (pair? (lst))
    {
      result = result + 1;
      lst = cdr (lst);
    }
  return result;
}

any slength = string_length;
any vlength = vector_length;
// dlength is in dlist.mud

// reverse:

any lreverse(lst)
"l1 -> l2. Returns reverse of l1"
{
  any result;

  while (pair?(lst))
    {
      result = car(lst) . result;
      lst = cdr (lst);
    }
  return result;
}

any dreverse(d1)
"d1 -> d2. Returns a list with the contents of d1 in reverse order"
{
  if (d1 == null)
    d1;
  else
    {
      any d2, scan = d1;

      for (;;)
	{
	  d2 = dcons!(scan[0], d2);
	  scan = dnext(scan);
	  if (scan == d1) return d2;
	}
    }
}

any sreverse(s1)
"s1 -> s2. Returns string with all characters reversed"
{
  any l, s2, i;
  i = l = string_length(s1);
  s2 = make_string(l);
  l = l - 1;
  while ((i = i - 1) >= 0) s2[i] = s1[l - i];
  return s2;
}

any vreverse(v1)
"v1 -> v2. Returns vector with all elements reversed"
{
  any l, v2, i;
  i = l = vector_length(v1);
  v2 = make_vector(l);
  l = l - 1;
  while ((i = i - 1) >= 0) v2[i] = v1[l - i];
  return v2;
}

// reverse!:

any lreverse!(l1)
"l1 -> l2. Reverses list l1, destructively"
{
  if (l1 == null)
    null;
  else
    {
      any prev = l1, next;

      l1 = cdr(l1);
      set_cdr!(prev, null);
      while (l1 != null)
	{
	  next = cdr(l1);
	  set_cdr!(l1, prev);
	  prev = l1;
	  l1 = next;
	}
      prev;
    }
}

any dreverse!(d1)
"d1 -> d2. Reverses list d1, destructively"
{
  if (d1 == null)
    null;
  else
    {
      any scan = d1;

    loop: for (;;)
	{
	  any swap = scan[1];
	  scan[1] = scan[2];
	  scan[2] = swap;

	  scan = swap;
	  if (scan == d1) break loop d1[1]; // last element is now first
	}
    }
}

any sreverse!(s1)
"s1 -> s2. Returns string with all elements reversed"
{
  any l, i, swap;
  l = string_length(s1);

  i = l >> 1;
  l = l - 1;

  while ((i = i - 1) >= 0)
    {
      swap = s1[i];
      s1[i] = s1[l - i];
      s1[l - i] = swap;
    }
  return s1;
}

any vreverse!(v1)
"v1 -> v2. Returns vector with all elements reversed"
{
  any l, i, swap;
  l = vector_length(v1);

  i = l >> 1;
  l = l - 1;

  while ((i = i - 1) >= 0)
    {
      swap = v1[i];
      v1[i] = v1[l - i];
      v1[l - i] = swap;
    }
  return v1;
}

// append:

any lappend(l1, l2)
"l1 l2 -> l3. Appends l2 to l1 as l3 (shares tail with l2)"
{
  if (l1 == null)
    l2;
  else
    {
      any l3, scan3, next3;

      scan3 = l3 = car(l1) . null;
      for (;;)
	{
	  l1 = cdr(l1);
	  if (l1 == null)
	    {
	      set_cdr!(scan3, l2);
	      return l3;
	    }
	  set_cdr!(scan3, next3 = car(l1) . null);
	  scan3 = next3;
	}
    }
}
    
any sappend = string_append;

any dmerge!=null; // missing (in dlist.mud)
any dappend(d1, d2)
"d1 d2 -> d3. Returns a new list d3 with the contents of d1 and d2"
  dmerge!(dcopy(d1), dcopy(d2));

any vappend(v1, v2)
"v1 v2 -> v3. Returns a new vector v3 with the contents of v1 and v2"
{
  any l, l1, l2, v, i, j;

  l1 = vector_length(v1);
  l2 = vector_length(v2);
  l = l1 + l2;
  v = make_vector(l);

  i = l1;
  while ((i = i - 1) >= 0) v[i] = v1[i];
  i = l2; j = l1 + l2;
  while ((i = i - 1) >= 0) v[j = j - 1] = v2[i];
  return v;
}

// append!:

any lappend!(l1, l2)
"l1 l2 -> l3. l3 is l2 appended to l1, destructively"
{
  if (l1 == null)
    l2;
  else
    {
      any end = l1, next;

      while (null != (next = cdr(end))) end = next;
      set_cdr!(end, l2);
      l1;
    }
}

any dappend! = dmerge!;

// No sappend!, vappend! (no sense)

// map:

any lmap(f, l)
"fn l1 -> l2. Filters list l1 according to function fn"
{
  if (l == null)
    null;
  else
    {
      any first, last;

      last = first = f(car(l)) . null;
      l = cdr(l);
      while (l != null)
	{
	  any new = f(car(l)) . null;
	  set_cdr!(last, new);
	  last = new;
	  l = cdr(l);
	}
      first;
    }
}

any dmap(f, d)
"fn d1 -> d2. Returns result of applying fn to the elements of d1, in order"
{
  if (d == null) 
    null;
  else
    {
      any first, scan = d;
      first = dcons!(f(dget(scan)), null);
      for (;;)
	{
	  scan = dnext(scan);
	  if (scan == d) return first;
	  dcons!(f(dget(scan)), first);
	}
    }
}

any vmap(f, v)
"c v1 -> v2. Applies c to every element of v1 (from 1st to last) and makes a vector v2 of the results"
{
  any r, l = vector_length(v);
  r = make_vector(l);
  for (int i = 0; i < l; i++)
    r[i] = f(v[i]); 
  return r;
}

any smap(f, s)
"fn s1 -> s2. Applies c to every element of s1 (from 1st to last) and makes a string s2 of the results"
{
  any r, l = string_length(s);

  r = make_string(l);
  for (int i = 0; i < l; i++)
    r[i] = f(s[i]);
  r;
}


// map!:

any lmap!(f, l)
"fn l1 -> l1. Applies fn to every element of l1 (from 1st to last) and returns the modified list with the results"
{
  any s = l;

  while (l != null)
    {
      set_car!(l, f(car(l)));
      l = cdr(l);
    }
  s;
}

any dmap!(f, d)
"fn d1 -> d1. Applies fn to every element of d1 (from 1st to last) and returns the modified list with the results"
{
  if (d == null) 
    null;
  else
    {
      any scan = d;
      for (;;)
	{
	  dset!(scan, f(dget(scan)));
	  scan = dnext(scan);
	  if (scan == d) return d;
	}
    }
}

any vmap!(f, v)
"c v1 -> v1. Applies c to every element of v1 (from 1st to last) and returns the modified vector with the results"
{
  any l = vector_length(v);
  for (any i = 0; i < l; i++)
    v[i] = f(v[i]);
  v;
}

any smap!(f, s)
"fn s1 -> s1. Applies c to every element of s1 (from 1st to last) and returns modified string with the results"
{
  any l = string_length(s);
  for (any i = 0; i < l; i++)
    s[i] = f(s[i]);
  s;
}

// foreach:

any lforeach(f, l)
"fn l -> . Applies fn to every element of l"
{
  while (l != null)
    {
      f(car(l));
      l = cdr(l);
    }
}

any dforeach(f, d)
"fn d1 -> . Applies fn to every element of d1 (from 1st to last)"
{
  if (d != null)
    {
      any scan = d;
      for (;;)
	{
	  f(dget(scan));
	  scan = dnext(scan);
	  if (scan == d) return;
	}
    }
}

any vforeach(f, v)
"c v1 -> . Applies c to every element of v1 (from 1st to last)"
{
  any l;
  l = vector_length(v);
  for (any i = 0; i < l; i++)
    f(v[i]);
}

any sforeach(f, s)
"fn s1 -> . Applies c to every element of s1 (from 1st to last)"
{
  any l = string_length(s);
  for (any i = 0; i < l; i++)
    f(s[i]); 
}

// exists?:

any lexists?(f, l)
"fn l -> x. Returns first element x of l for which fn(x) is true, false if none found"
{
  for (;;)
    {
      any x;

      if (l == null) return false;
      else if (f(x = car(l))) return x;
      else l = cdr(l);
    }
}

any dexists?(f, d) 
"fn d -> x. Returns first element x of d for which fn(x) is true, false if none found"
{
  if (d == null) 
    false;
  else
    {
      any scan = d;
      for (;;)
	if (f(dget(scan))) return dget(scan);
	else
	  {
	    scan = dnext(scan);
	    if (scan == d) return false;
	  }
    }
}

any vexists?(f, v) 
"fn v -> . Returns first element x of v for which fn(x) is true, false if none found"
{
  any i = 0, l = vector_length(v);
  for (;;)
    if (i == l) return false;
    else if (f(v[i])) return v[i];
    else i = i + 1;
}

any sexists?(f, s)
"fn s -> . Returns first element x of s for which fn(x) is true, false if none found"
{
  any i = 0, l = string_length(s);
  for (;;)
    if (i == l) return false;
    else if (f(s[i])) return s[i];
    else i = i + 1;
}

// forall?:

any lforall?(f, l)
"fn l -> b. Returns true if fn(x) is true for all elements of list l (in order)"
{
  for (;;)
    if (l == null) return true;
    else if (!f(car(l))) return false;
    else l = cdr(l);
}

any dforall?(f, d)
"fn d -> b. Returns true if fn(x) is true for all elements of list d (in order)"
{
  if (d == null) 
    false;
  else
    {
      any scan = d;

      for (;;)
	if (!f(dget(scan))) return false;
	else
	  {
	    scan = dnext(scan);
	    if (scan == d) return true;
	  }
    }
}

any vforall?(f, v)
"fn v -> b. Returns true if fn(x) is true for all elements of v (in order)"
{
  any i = 0, l = vector_length(v);
  for (;;)
    if (i == l) return true;
    else if (!f(v[i])) return false;
    else i = i + 1;
}

any sforall?(f, s)
"fn s -> b. Returns true if fn(x) is true for all elements of s (in order)"
{
  any i = 0, l = string_length(s);
  for (;;)
    if (i == l) return true;
    else if (!f(s[i])) return false;
    else i = i + 1;
}

// reduce:

any lreduce(f, x, l)
"fn x l -> . Reduces list l with function fn and initial value x"
{
  for (; l != null; l = cdr(l))
    x = f(car(l), x);
  x;
}

any dreduce(f, x, d)
"fn x d -> . Reduces list d with function fn and initial value x"
{
  if (d == null)
    x;
  else
    {
      any scan = d;
      for (;;)
	{
	  x = f(dget(scan), x);
	  scan = dnext(scan);
	  if (scan == d) return x;
	}
    }
}

any vreduce(f, x, v)
"fn x d -> . Reduces v with function fn and initial value x"
{
  any l = vector_length(v);
  for (any i = 0; i < l; i++)
    x = f(v[i], x);
  x;
}

any sreduce(f, x, s)
"fn x s -> . Reduces s with function fn and initial value x"
{
  any l = string_length(s);
  for (any i = 0; i < l; i++)
    x = f(s[i], x);
  x;
}

// delete:

// These could be optimised

any ldelete(x, l)
"x l1 -> l2. Returns l1 without any occurrences of x"
  lfilter(fn (y) y != x, l);

any ddelete(x, d)
"x d1 -> d2. Returns d1 without any occurrences of x"
  dfilter(fn (y) y != x, d);

any vdelete(x, v)
"x v1 -> v2. Returns v1 without any occurrences of x"
  vfilter(fn (y) y != x, v);

any sdelete(x, s)
"x s1 -> s2. Returns s1 without any occurrences of x"
  sfilter(fn (y) y != x, s);


// delete!:

any ldelete!(x, l)
"x l1 -> l2. l2 is l1 with all x's deleted"
  lfilter!(fn (y) x != y, l);

any ddelete!(x, d)
"x d1 -> d2. Returns d1 without any occurrences of x"
  dfilter!(fn (y) y != x, d);

// sdelete! and vdelete! make no sense

// filter:

any lfilter(f, l)
"fn l1 -> l2. Returns l1 filtered by function fn"
{
  any first, last, x;

  for (; l != null; l = cdr(l))
    if (f(x = car(l)))
      {
	any new = x . null;
	if (first == null) first = last = new;
	else
	  {
	    set_cdr!(last, new);
	    last = new;
	  }
      }
  first;
}

any dfilter(f, d)
"fn d1 -> d2. Returns d1 filtered by function fn"
{
  if (d == null)
    null;
  else
    {
      any junk = dcons!(null, null), scan = d;
      for (;;)
	{
	  if (f(dget(scan))) dcons!(dget(scan), junk);
	  scan = dnext(scan);
	  if (scan == d) return dremove!(junk, junk);
	}
    }
}

any vfilter(f, v)
"fn v1 -> v2. Returns v1 filtered by function fn"
{
  any keep, result, l, i, count;

  // tricky, as f should only be called once

  // find elements to keep
  l = vector_length(v);
  keep = make_string(l);
  i = count = 0;
  for (i = count = 0; i < l; i++)
    if (keep[i] = (f(v[i]) != 0)) count = count + 1;

  // copy to result
  result = make_vector(count);
  while (count > 0)
    {
      // find next element kept
      while (!keep[i = i - 1]) ;
      result[count = count - 1] = v[i];
    }
  result;
}

any sfilter(f, s)
"fn s1 -> s2. Returns s1 filtered by function fn"
{
  any keep, result, l, i, count;

  // tricky, as f should only be called once

  // find elements to keep
  l = string_length(s);
  keep = make_string(l);
  for (i = count = 0; i < l; i++)
    if (keep[i] = (f(s[i]) != 0)) count = count + 1;

  // copy to result
  result = make_string(count);
  while (count > 0)
    {
      // find next element kept
      while (!keep[i = i - 1]) ;
      result[count = count - 1] = s[i];
    }
  result;
}

// filter!:

any lfilter!(f, l)
"fn l1 -> l2. Returns l1 filtered by function fn"
{
  any check, trail;

  for (;;) // find first
    if (!pair?(l)) return null;
    else if (f(car(l))) break; // found first
    else l = cdr(l);

  check = cdr(l);
  trail = l;

  while (pair?(check))
    {
      if (!f(car(check))) set_cdr!(trail, cdr(check))
      else trail = check;
      check = cdr(check);
    }
  l;
}

any dfilter!(f, d)
"fn d1 -> d2. Returns d1 filtered by function fn"
{
  if (d == null)
    null;
  else
    {
      any last = dprev(d);

      while (d != last)
	{
	  if (!f(dget(d))) d = dremove!(d, d)
	  else d = dnext(d);
	}
      // Handle last element. Return new first element ...
      if (!f(dget(last))) dremove!(last, last)
      else dnext(last);
    }
}

// sfilter! and vfilter! make no sense

// find?:

any lfind?(x, l)
"x l -> b. Returns TRUE if x is in l"
{
  for (;;)
    if (l == null) return false;
    else if (car(l) == x) return true;
    else l = cdr(l);
}
    
any dfind?(x, d)
"x d -> b. Returns TRUE if x is in d"
{
  if (d == null) 
    false;
  else
    {
      any scan = d;
      for (;;)
	if (dget(scan) == x) return true;
	else
	  {
	    scan = dnext(scan);
	    if (scan == d) return false;
	  }
    }
}

any vfind?(x, v)
"x v -> b. Returns TRUE if x is in v"
{
  any i = 0, l = vector_length(v);
  for (;;)
    if (i == l) return false;
    else if (v[i] == x) return true;
    else i = i + 1;
}

any sfind? = fn (x, s)
"x s -> b. Returns TRUE if x is in s"
{
  any i = 0, l = string_length(s);
  for (;;)
    if (i == l) return false;
    else if (s[i] == x) return true;
    else i = i + 1;
}; /* ; because we defined with a 'fn' expression */
