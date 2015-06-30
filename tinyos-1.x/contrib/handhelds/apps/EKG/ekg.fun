// List of functions that can be called from within a web page

int ekg_lock();
int ekg_unlock();
int ekg_status( int );
int ekg_samples_per_packet();
int ekg_packet_index();
int ekg_sample( int );
string ekg_number();
int ekg_uid_byte( int );
int ekg_uid_family();
int ekg_uid_crc();
int ekg_revision();
