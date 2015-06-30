result_t rcombine5(result_t r1, result_t r2, result_t r3, 
                   result_t r4, result_t r5)
{
  return rcombine(rcombine(r1, r2), rcombine3(r3, r4, r5));
}

result_t rcombine6(result_t r1, result_t r2, result_t r3,
                   result_t r4, result_t r5, result_t r6)
{
  return rcombine(rcombine3(r1, r2, r3), rcombine3(r4, r5, r6));
}

result_t rcombine7(result_t r1, result_t r2, result_t r3, 
                   result_t r4, result_t r5, result_t r6,
                   result_t r7)
{
  return rcombine(rcombine3(r1, r2, r3), rcombine4(r4, r5, r6, r7));
}

result_t rcombine8(result_t r1, result_t r2, result_t r3, 
                   result_t r4, result_t r5, result_t r6,
                   result_t r7, result_t r8)
{
  return rcombine(rcombine4(r1, r2, r3, r4), rcombine4(r5, r6, r7, r8));
}

result_t rcombine9(result_t r1, result_t r2, result_t r3,
                   result_t r4, result_t r5, result_t r6,
                   result_t r7, result_t r8, result_t r9)
{
  return rcombine(rcombine4(r1, r2, r3, r4), rcombine5(r5, r6, r7, r8, r9));
}

