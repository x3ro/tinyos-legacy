lmap = fn (f, l) 
     if (l == null) null
     else f(car(l)) . lmap(f, cdr(l));

repeat = fn (n, f)
     while (n-- > 0) f(); 

repeat(1000, fn() lmap(fn (x) x + 1, list(1, 2, 3)));
