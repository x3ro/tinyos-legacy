//$Id: bool_combine.h,v 1.1 2005/06/29 05:06:47 cssharp Exp $
#ifndef _H_bool_combine_h
#define _H_bool_combine_h


// bool_all_t: all true

bool combine_bool_all( bool a, bool b );
typedef bool bool_all_t __attribute__((combine(combine_bool_all)));

bool_all_t combine_bool_all( bool_all_t a, bool_all_t b )
{
  return a && b;
}


// bool_any_t: any true

bool combine_bool_any( bool a, bool b );
typedef bool bool_any_t __attribute__((combine(combine_bool_any)));

bool_any_t combine_bool_any( bool_any_t a, bool_any_t b )
{
  return a || b;
}

#endif//_H_bool_combine_h

