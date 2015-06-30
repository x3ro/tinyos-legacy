-- SQL for creating tables to initialize a GSK database.
-- This script is platform specific.  It uses some PostgreSQL specific
-- data types (e.g., bytea).

-- task_query_log is a complete log of all queries submitted to 
-- the sensor network
drop table task_query_log cascade;
create table task_query_log (
	query_id int primary key,	/* unique id for queries */
	tinydb_qid smallint,		/* TinyDB query id, 1-byte */
	query_text text not null,	/* query text in TinyDB SQL */
	query_type varchar(20) not null, /* query type: sensor or health */
	table_name varchar(100) not null unique /* name of table where the query results are logged */
	);

-- task_query_time_log records the query start and stop times
drop table task_query_time_log;
create table task_query_time_log (
	query_id int references task_query_log,	/* query id */
	start_time timestamp not null,			/* query start time */
	stop_time timestamp, 					/* query stop time */
	primary key(query_id, start_time)
	);

-- task_command_log is a complete log of all commands submitted to
-- the sensor network
drop table task_command_log cascade;
create table task_command_log (
	command_id	int primary key, /* unique command id */
	submit_time timestamp, /* command submission time */
	command_name varchar(100), /* command name, e.g., reset, sample_rate, ping, calibrate, etc. */
	node_id int, /* target node id, -1 means all nodes */
	query_id int, /* query id the command is targeting, -1 means all queries */
	command_arg int /* single integer argument value, will generalize later */
	);

-- task_command_acks records the acknowledgements from each node in reponse to
-- a command issued from the server.
drop table task_command_acks;
create table task_command_acks (
	command_id	int references task_command_log,
	ack_time	timestamp, /* timestamp when ack comes in */
	node_id		int, /* node id from which the ack is sent */
	query_id	int, /* query id if command is targeting a particular query */
	epoch		int, /* last epoch number for the query */
	sample_rate int /* all acks include the current sample rate in seconds */
	);

-- task_packet_log is a complete log of all raw packets received from 
-- the sensor network.
-- There will also be a per-query table (specified by task_query_log.table_name)
-- logging the query result tuples.
drop table task_packet_log;
create table task_packet_log (
	query_id int references task_query_log, /* id of query that generated the packet */
	epoch int, 		/* epoch number */
	server_time timestamp, /* time received at server */
	mote_time timestamp, 	/* logical time stamped by mote */
	mote_id int, 	/* id of mote that generated the packet */
	raw_packet bytea /* raw packet bytes */
	);

-- task_health_log is a complete log of network health and statistics
-- that can be collected from the sensor network.  It includes all
-- possible network health and statistics related attributes.  Each
-- health query will only collect a subset of these attributes.  The
-- attributes that are not included in the query will be filled with
-- NULL values.
drop table task_health_log;
create table task_health_log (
	query_id int references task_query_log,	/* query id */
	epoch int, 	/* epoch number */
	server_time timestamp, /* time received at server */
	mote_time timestamp, 	/* logical time stamped by mote */
	mote_id int, 			/* mote id */
	parent int, 			/* parent id in routing tree */
	voltage int,			/* battery voltage */
	contention int			/* radio contention */
	/* The exact list of health&stat attributes is yet to be finalized. */
	);

-- task_last_query_id implements a persistent counter for generating
-- unique GSK query ids
drop table task_next_query_id;
create table task_next_query_id (
	query_id int, 	/* next query id */
	tinydb_qid smallint, /* next tinydb query id, 1 byte */
	command_id int /* next command id */
	);
-- query 0 is reserved for the calibration query
insert into task_next_query_id values (1, 1, 0);

-- task_current_results is a view into queryN_results table 
-- for the last query executed.
-- initialized as task_query_log as a placeholder
drop view task_current_results;
create view task_current_results as select * from task_query_log;

-- task_attributes contains information about all the attributes
-- that can be queries from the sensor network
drop table task_attributes;
create table task_attributes (
	name varchar(8), 	/* attribute name, limited to 8 characters */
	typeid int, 		/* type of attribute */
	power_cons int, /* per sample power consumption rate */
	description varchar(1000) /* description of the attribute */
	);
insert into task_attributes values ('nodeid', 3, 1, 'node id');
insert into task_attributes values ('light', 3, 1, 'light sensor reading');
insert into task_attributes values ('temp', 3, 1, 'temperature sensor reading');
insert into task_attributes values ('parent', 3, 1, 'parent node id in routing tree');
insert into task_attributes values ('accel_x', 3, 1, 'accelerometer reading in x axis');
insert into task_attributes values ('accel_y', 3, 1, 'accelerometer reading in y axis');
insert into task_attributes values ('mag_x', 3, 1, 'magnetometer reading in x axis');
insert into task_attributes values ('mag_y', 3, 1, 'magnetometer reading in y axis');
insert into task_attributes values ('noise', 3, 1, 'aggregated microphone readings');
insert into task_attributes values ('tones', 3, 1, 'aggregated number of tones detected');
insert into task_attributes values ('voltage', 3, 1, 'battery voltage level');
insert into task_attributes values ('rawtone', 3, 1, 'raw tone detector output: 1 detected 0 otherwise');
insert into task_attributes values ('rawmic', 3, 1, 'raw microphone reading');
insert into task_attributes values ('freeram', 3, 1, 'amount of RAM available in bytes');
insert into task_attributes values ('qlen', 1, 1, 'global send queue length');
insert into task_attributes values ('mhqlen', 1, 1, 'multi-hop forward queue length');
insert into task_attributes values ('depth', 1, 1, 'multi-hop depth');
insert into task_attributes values ('timelo', 4, 1, 'low 32-bit of mote logical time');
insert into task_attributes values ('timehi', 4, 1, 'high 32-bit of mote logical time');
insert into task_attributes values ('qual', 1, 1, 'quality of multi-hop parent');
insert into task_attributes values ('humid', 3, 1, 'Senirion Humidity sensor humidity reading');
insert into task_attributes values ('humtemp', 3, 1, 'Senirion Humidity sensor temperature reading');
insert into task_attributes values ('echo10', 3, 1, 'Echo10 soil moisture sensor temperature reading');
insert into task_attributes values ('taosbot', 3, 1, 'Bottom Taos Photo sensor reading');
insert into task_attributes values ('taostop', 3, 1, 'Top Taos Photo sensor reading');
insert into task_attributes values ('press', 3, 1, 'Intersema Pressure sensor pressure reading');
insert into task_attributes values ('prtemp', 3, 1, 'Intersema Pressure sensor temperature reading');
insert into task_attributes values ('prcalib', 9, 1, 'Intersema Pressure sensor calibration reading');
insert into task_attributes values ('hamatop', 3, 1, 'Top Hamamatsu light sensor reading');
insert into task_attributes values ('hamabot', 3, 1, 'Bottom Hamamatsu light sensor reading');
insert into task_attributes values ('thermo', 3, 1, 'Melexis sensor thermopile reading');
insert into task_attributes values ('thmtemp', 3, 1, 'Melexis sensor temperature reading');
-- insert into task_attributes values ('content', 3, 1, 'radio contention');

-- task_aggregates contains information about all aggregates that
-- are supported by GSK
drop table task_aggregates;
create table task_aggregates (
	name varchar(32), 	/* name of aggregate */
	return_type int, 	/* return type of aggregate */
	num_args int, 		/* number of arguments */
	arg_type int, 		/* type of the non-constant argument */
	description varchar(1000)	/* description of the aggregate */
	);
insert into task_aggregates values ('winavg', 3, 3, 3, 'temporal windowed average');
insert into task_aggregates values ('winsum', 3, 3, 3, 'temporal windowed sum');
insert into task_aggregates values ('winmin', 3, 3, 3, 'temporal windowed minimum');
insert into task_aggregates values ('winmax', 3, 3, 3, 'temporal windowed maximum');
insert into task_aggregates values ('wincnt', 3, 3, 3, 'temporal windowed count');

-- task_commands contains information about all sensor network 
-- commands supported by GSK
drop table task_commands;
create table task_commands (
	name varchar(8), 	/* name of command */
	return_type int, 	/* return type of the command */
	num_args int, 		/* number of arguments */
	arg_types int[], 	/* argument types */
	description varchar(1000)	/* brief description */
	);
insert into task_commands values ('SetLedR', 9, 1, '{1}', 'SetLedR(0) turns off the red LED, SetLedR(1) turns on the red LED, SetLedR(2) toggles the red LED');
insert into task_commands values ('SetLedY', 9, 1, '{1}', 'SetLedY(0) turns off the yellow LED, SetLedY(1) turns on the yellow LED, SetLedY(2) toggles the yellow LED');
insert into task_commands values ('SetLedG', 9, 1, '{1}', 'SetLedG(0) turns off the green LED, SetLedG(1) turns on the green LED, SetLedG(2) toggles the green LED');
insert into task_commands values ('SetPot', 9, 1, '{1}', 'set potentiometer level');
insert into task_commands values ('Reset', 9, 0, '{}', 'reboot mote');
insert into task_commands values ('LogClr', 9, 0, '{}', 'clear tuple log in EEPROM');
-- insert into task_commands values ('SetSnd', 9, 1, '{2}', 'turn on sounder for n milliseconds');

-- task_client_info contains opaque information about task clients
-- such as layouts.
drop table task_client_info cascade;
create table task_client_info (
	name varchar(100) primary key, 	/* name of client info */
	type varchar(100),	/* java type of client info */
	clientinfo bytea	/* opaque client info object */
	);

-- task_mote_info contains opaque per-mote client information relative to
-- a particular client info.
drop table task_mote_info;
create table task_mote_info (
	mote_id int,	/* mote id */
	x_coord	double precision, /* x coordinate */
	y_coord	double precision, /* y coordinate */
	z_coord	double precision, /* z coordinate */
	calib 	bytea, /* calibration coefficiences, raw bytes from motes */ 
	moteinfo bytea,	/* opaque mote info object */
	clientinfo_name varchar(100) references task_client_info, /* client info name */
	primary key (mote_id, clientinfo_name)
	);

create or replace function humidity(int /* raw humidity */) returns real
	as 'select (-4 + 0.0405 * $1 + -2.8e-6 * $1 * $1)::real as result;'
	language sql;

create or replace function humid_temp(int /* raw temperature */) returns real
	as 'select (-38.4 + 0.0098 * $1)::real as result;'
	language sql;

create or replace function humid_adj(int /* raw humidity */, int /* raw temperature */) returns real
	as 'select ((humid_temp($2) - 25) * (0.01 + 0.00008 * $1) + humidity($1))::real as result;'
	language sql;

CREATE FUNCTION plpgsql_call_handler () RETURNS language_handler
    AS '$libdir/plpgsql', 'plpgsql_call_handler'
    LANGUAGE c;


CREATE TRUSTED PROCEDURAL LANGUAGE plpgsql HANDLER plpgsql_call_handler;

create or replace function photo(int /* channel 0 */, int /* channel 1 */) returns real
	as 'declare
			s0 int;
			cc0 int;
			s1 int;
			cc1 int;
			adccount0 int;
			adccount1 int;
			lux real := 0;
		begin
			s0 := $1 & 15;
			cc0 := (($1 & 127) >> 4) & 7;
			s1 := $2 & 15;
			cc1 := (($2 & 127) >> 4) & 7;
			-- check if we are railed
			if s0 = 15 and s1 = 15 and cc0 = 7 and cc1 = 7
			then return null;
			end if;

			adccount0 := (16.5 * (2^cc0 - 1))::int + (s0 * 2^cc0)::int;
			adccount1 := (16.5 * (2^cc1 - 1))::int + (s1 * 2^cc1)::int;

			if adccount0 = 0 then return null; end if;
			if (adccount1 / adccount0) > 27 then return 0.0; end if;
			lux := adccount0 * 0.46 * exp(-3.13 * (adccount1 / adccount0));
			return lux;
		end;'
	language 'plpgsql';

create or replace function thermopile(int /* raw thermopile */) returns real
	as 'select ((($1 >> 4) * (120 - (-20))) / (2^12 - 1) + (-20))::real as result;'
	language sql;

create or replace function thermistor(int /* raw temperature */) returns real
	as 'select ((($1 >> 4) * (85 - (-20))) / (2^12 - 1) + (-20))::real as result;'
	language sql;

create or replace function voltage(int /* raw voltage */) returns real
	as 'select (case when $1 = 0 then 0 else 0.58 * 1024 / $1 end)::real as result;'
	language sql;

create or replace function hamamatsu_current(int /* raw hamamatsu */, int /* raw voltage */) returns real
	as 'select (($1 * voltage($2) / 1024.0) / 5.0)::real as result;'
	language sql;

create or replace function hamamatsu(int /* raw hamamatsu */, int /* raw voltage */) returns real
	as 'select (hamamatsu_current($1, $2) * 1e6)::real as result;'
	language sql;

create or replace function pressure_mbar(int /* raw pressure */, int /* raw temperature */, bytea /* calibration */) returns real
	as 'declare
			c1 int; c2 int; c3 int; c4 int; c5 int; c6 int;
			calib0 int; calib1 int; calib2 int; calib3 int;
			ut1 int;
			dt int;
			temp real;
			off real;
			sens real;
			x real;
			p real;
		begin
			-- parse calibration coefficiences out of byte array
			calib0 := get_byte($3, 0) & 255;
			calib0 := calib0 | (((get_byte($3, 1) & 255) << 8) & 65280);
			calib1 := get_byte($3, 2) & 255;
			calib1 := calib1 | (((get_byte($3, 3) & 255) << 8) & 65280);
			calib2 := get_byte($3, 4) & 255;
			calib2 := calib2 | (((get_byte($3, 5) & 255) << 8) & 65280);
			calib3 := get_byte($3, 6) & 255;
			calib3 := calib3 | (((get_byte($3, 7) & 255) << 8) & 65280);

			c1 := calib0 >> 1;
			c2 := calib2 & 63;
			c2 := c2 << 6;
			c2 := c2 | (calib3 & 63);
			c3 := calib3 >> 6;
			c4 := calib2 >> 6;
			c5 := calib0 << 10;
			c5 := c5 & 1024;
			c5 := c5 + (calib1 >> 6);
			c6 := calib1 & 63;

			ut1 := 8 * c5 + 20224;
			dt := $2 - ut1;
			temp := 200 + dt * (c6 + 50) / 1024;
			off := c2 * 4 + ((c4 - 512) * dt) / 4096;
			sens := c1 + (c3 * dt) / 1024 + 24576;
			x := (sens * ($1 - 7168)) / 16384 - off; 
			p := x * 100 / 32 + 250 * 100;
			return p / 100;
		end;'
	language 'plpgsql';

create or replace function pressure_inHg(int /* raw pressure */, int /* raw temperature */, bytea /* calibration */) returns real
	as 'declare
			c1 int; c2 int; c3 int; c4 int; c5 int; c6 int;
			calib0 int; calib1 int; calib2 int; calib3 int;
			ut1 int;
			dt int;
			off real;
			sens real;
			x real;
			p real;
		begin
			-- parse calibration coefficiences out of byte array
			calib0 := get_byte($3, 0) & 255;
			calib0 := calib0 | (((get_byte($3, 1) & 255) << 8) & 65280);
			calib1 := get_byte($3, 2) & 255;
			calib1 := calib1 | (((get_byte($3, 3) & 255) << 8) & 65280);
			calib2 := get_byte($3, 4) & 255;
			calib2 := calib2 | (((get_byte($3, 5) & 255) << 8) & 65280);
			calib3 := get_byte($3, 6) & 255;
			calib3 := calib3 | (((get_byte($3, 7) & 255) << 8) & 65280);

			c1 := calib0 >> 1;
			c2 := calib2 & 63;
			c2 := c2 << 6;
			c2 := c2 | (calib3 & 63);
			c3 := calib3 >> 6;
			c4 := calib2 >> 6;
			c5 := calib0 << 10;
			c5 := c5 & 1024;
			c5 := c5 + (calib1 >> 6);
			c6 := calib1 & 63;

			ut1 := 8 * c5 + 20224;
			dt := $2 - ut1;
			off := c2 * 4 + ((c4 - 512) * dt) / 4096;
			sens := c1 + (c3 * dt) / 1024 + 24576;
			x := (sens * ($1 - 7168)) / 16384 - off; 
			p := x * 100 / 32 + 250 * 100;
			return p / (100 * 33.864);
		end;'
	language 'plpgsql';

create or replace function pressure_temp(int /* raw temperature */, bytea /* calibration */) returns real
	as 'declare
			c1 int; c2 int; c3 int; c4 int; c5 int; c6 int;
			calib0 int; calib1 int; calib2 int; calib3 int;
			ut1 int;
			dt int;
			temp real;
		begin
			-- parse calibration coefficiences out of byte array
			calib0 := get_byte($2, 0) & 255;
			calib0 := calib0 | (((get_byte($2, 1) & 255) << 8) & 65280);
			calib1 := get_byte($2, 2) & 255;
			calib1 := calib1 | (((get_byte($2, 3) & 255) << 8) & 65280);
			calib2 := get_byte($2, 4) & 255;
			calib2 := calib2 | (((get_byte($2, 5) & 255) << 8) & 65280);
			calib3 := get_byte($2, 6) & 255;
			calib3 := calib3 | (((get_byte($2, 7) & 255) << 8) & 65280);

			c1 := calib0 >> 1;
			c2 := calib2 & 63;
			c2 := c2 << 6;
			c2 := c2 | (calib3 & 63);
			c3 := calib3 >> 6;
			c4 := calib2 >> 6;
			c5 := calib0 << 10;
			c5 := c5 & 1024;
			c5 := c5 + (calib1 >> 6);
			c6 := calib1 & 63;

			ut1 := 8 * c5 + 20224;
			dt := $1 - ut1;
			temp := 200 + dt * (c6 + 50) / 1024;
			return temp / 10;
		end;'
	language 'plpgsql';
