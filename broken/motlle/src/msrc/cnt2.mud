infinite = fn ()
[ | i |
  i = 3;
  while (1)
    [
      led!(i);
      i = i + 1;
      sleep(1);
    ];
];
