inc=fn(x)x+"a";
lmap=fn(f,l) if (l==null) null else f(car(l)) . lmap(f, cdr(l));
garbage_collect();
lmap(display, lmap(inc, '("a" "b" "c")));
newline();
