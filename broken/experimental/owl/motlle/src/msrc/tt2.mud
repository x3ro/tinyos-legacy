inc=fn(x)x+1;
lmap=fn(f,l) if (l==null) null else f(car(l)) . lmap(f, cdr(l));
lmap(display, lmap(inc, '(1 2 3)));
newline();
dump("test1", fn () lmap(display, lmap(inc, '(1 2 3))));
