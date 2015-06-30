
create table weather (
 	packet_time  timestamp with time zone,
 	node_id        integer,
 	light_reading  integer,
 	temp_reading   integer,
	thermopile_reading integer,
	thermistor_reading integer,
	humidity_reading integer,
	intersema_pressure_reading integer,
	intersema_pressure_raw integer,
	intersema_temp_reading integer,
	intersema_temp_raw integer,
 	voltage_reading integer,
 	seqno          integer,
 	crc            integer,
 	packet         bytea  );

create table mote_data (
	node_id integer,
	intersema_calibration bytea,
	gps_zone integer,
	gps_hemisphere char,
	easting integer,
	northing integer, 
	location varchar(80),
	asset integer,
	wb_num
);

create table last_heard (
	node_id integer,
	last_seqno integer
);
 
insert into last_heard (node_id) select distinct node_id from weather;