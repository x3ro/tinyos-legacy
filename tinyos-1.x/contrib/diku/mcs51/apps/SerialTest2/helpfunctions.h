
  /***********************************************************************
   ** Helper functions
  ***********************************************************************/
  int strlen(char s[])
  {
    int i;
    i = 0;
    while (s[i] != '\0')
      ++i;
    return i;
  }

  void reverse(char s[])
  {
    int c,i,j;

    for(i=0,j = strlen(s) - 1;i<j;i++,j--)
    {
      c = s[i];
      s[i] = s[j];
      s[j] = c;
    }
  }

  void itoa (int n, char s[])
  {
    int i, sign;

    if ((sign = n) < 0 )
      n = -n;
    i = 0;
    do {
      s[i++] = n % 10 + '0';
    } while ((n /= 10) > 0);
    if (sign < 0)
      s[i++] = '-';
    s[i] = '\0';
    reverse(s);
  }

  void strcpy(char *s, char *t) {
    while(((*s++) = (*t++)));
  }

  void strcat (char s[], char t[]) {
    int i, j;
    i = j = 0;

    while (s[i] != '\0')
      i++;
    while ((s[i++] = t[j++]) != '\0');
  }
