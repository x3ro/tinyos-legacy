inc=fn(x)x+1000;
lmap=fn(f,l) if (l==null) null else f(car(l)) . lmap(f, cdr(l));
garbage_collect();
lmap(display, lmap(inc, '(1 2 3)));
newline();
