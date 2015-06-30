drop table if exists service;
create table service (
	deviceid varchar(32) NOT NULL,
	sname varchar(32) NOT NULL,
	stype varchar(32) NOT NULL,
	port int(10) NOT NULL,
	status varchar(32) NOT NULL,
	expires datetime,
	last_updated timestamp,
	primary key (deviceid, port),
	index deviceid_index(deviceid)
);

drop table if exists patient;
create table patient (
	patientid varchar(32) not null,
	name varchar(64),
	last_updated timestamp,
	primary key (patientid)
);

drop table if exists device;
create table device (
	deviceid varchar(32) not null,
	name varchar(64),
	dtype varchar(64),
	ipaddr varchar(32) not null,
	expires datetime,
	last_updated timestamp,
	primary key (deviceid)
);

drop table if exists patientdevice;
create table patientdevice (
	deviceid varchar(32) not null,
	patientid varchar(32) not null,
	primary key (patientid, deviceid)
);


INSERT INTO patient VALUES ('bgs43675','Baby Girl Soliman', 20050321114523);
INSERT INTO patientdevice VALUES ('a0a0000000000065','bgs43675');
INSERT INTO device VALUES ('a0a0000000000065',NULL,'clipboard','',NULL,20050321115500);
