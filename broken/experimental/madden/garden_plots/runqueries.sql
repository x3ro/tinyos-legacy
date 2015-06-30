delete from calib_data;
insert into calib_data 
  select * from  gsk_query1_cooked where packet_time > '7/6/03';
drop table normalized_table;
select * into normalized_table from normalized;
copy normalized_table to '/tmp/data.txt' with delimiter ',';