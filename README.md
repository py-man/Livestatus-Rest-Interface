Livestatus-Rest-Interface
=========================

Rest interface for (Nagios) check_mk / live status - Returns results in JSON - negates using the check_mk interface.

This program deamonises a perl script and allows rest style calls to retrive data, the output of check_mk livestatus.
Output can be CSV or JSON, and PERL Dancer servers as the REST framework.

Requirements: 

Monitoring::Livestatus - From CPAN, to allow connectivity to socket or remote TCP port and query livestatus for nagios information

Log::Log4perl - From CPAN, to allowing for logging / debugging

Exporter - From CPAN

MIME::Base64 - From CPAN

REST::Client - From CPAN

LWP - From CPAN

Dancer - From CPAN, Framework to manage REST requests.




