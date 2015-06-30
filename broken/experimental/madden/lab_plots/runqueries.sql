drop table normalized_table;
select * into normalized_table from normalized where time > now() - '2 days'::reltime;
copy normalized_table to '/tmp/data.txt' with delimiter ',';