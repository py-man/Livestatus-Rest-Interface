#!/usr/bin/perl

=head1 NAME

rest-server.pl

=head1 SYNOPSIS

Multisite connection Section sets physical connectivity

=head1 DESCRIPTION

this script prints some information from a given Check_MK livestatus socket or server via a Simple RESTFUl interface

=head1 EXAMPLE

######example queries   
     { 'query' => "GET hostgroups\nColumns: members \n",
      'sub'   => "selectall_arrayref",
      'opt'   => {Slice => 1 }
    },
    { 'query' => "GET comments",
      'sub'   => "selectall_arrayref",
      'opt'   => {Slice => 1 }
    },
    { 'query' => "GET downtimes",
      'sub'   => "selectall_arrayref",
      'opt'   => {Slice => 1, Sum => 1}
    },
    { 'query' => "GET log\nFilter: time > ".(time() - 600)."\nLimit: 1",
      'sub'   => "selectall_arrayref",
      'opt'   => {Slice => 1, AddPeer => 1}
    },
    { 'query' => "GET services\nFilter: contacts >= nagiosadmin\nFilter: host_contacts >= test\nOr: 2\nColumns: host_name description contacts host_contacts",
      'sub'   => "selectall_arrayref",
   },
     #'opt'   => {Slice => 1, AddPeer => 0}
    { 'query' => "GET services\nFilter: host_name = *nag*\nFilter: description = test_flap_02\nOr: 2\nColumns: host_name description contacts host_contacts",
      'sub'   => "selectall_arrayref",
      'opt'   => {Slice => 1, AddPeer => 0}
    },
################   

./rest-server.pl

=head1 AUTHOR

2012, Kevin Brannigan, <kevin.brannigan@me.com>

==head1 Referenced Scripts 
http://search.cpan.org/~nierlein/Monitoring-Livestatus-0.74/lib/Monitoring/Livestatus.pm
2009, Sven Nierlein, <nierlein@cpan.org> - Perl Cpan Module


=cut

###Define CPAN modules to use
use warnings;
use strict;
use Data::Dumper;
use Getopt::Long;
use Pod::Usage;
use Time::HiRes qw( gettimeofday tv_interval );
use Log::Log4perl qw(:easy);
use Exporter;
use MIME::Base64;
use REST::Client;
#use JSON;
use LWP;
use Dancer;
use Monitoring::Livestatus;
use Dancer ':syntax';
use Dancer::Serializer::Mutable;

#Set defaults
set serializer => 'XML';
set serializer => 'JSON'; #json format responses
set 'session'	=> 'simple';
set 'logger'       => 'console';
set 'log'          => 'info';
set 'show_errors'  => 1;
set 'startup_info' => 1;
set 'warnings'     => 1;

my $multisite_server = "000.000.000.000";
my $prod_server = "000.000.000.001";
my $nonprod_server = "000.000.000.002";
  

our ($opt_h, $opt_v, @opt_f);
our $verbose = 0;
@opt_f = $multisite_server.":6557";

##The paths to access the queries
prefix '/livestatus/REST/search';

get '/:id' => sub {
    
    my $id   = params->{id};
    
    if ( $id =~ /hosts/ ){
    	my $from_livestatus = query_livestatus($id);
    	return $from_livestatus;
    }
    elsif ( $id =~ /services/ ){
    	my $from_livestatus = query_livestatus($id);
    	return $from_livestatus;
    }
    elsif ( $id =~ /all/ ){
        my $from_livestatus = query_livestatus($id);
        return $from_livestatus;
    }
    else{
    	return {id => $id};
    }
};

   
#start rest app server
dance;

##########################Functions Go here##############################
sub query_livestatus{
	
#livestatus interface
$Data::Dumper::Sortkeys = 1;


#########################################################################
#Multiste Connections 													#
#########################################################################
Log::Log4perl->easy_init($DEBUG);

#my $request = "";
my $request = shift;

our $nl = Monitoring::Livestatus->new(                                 
                                     peer      => [
            
							         			 {
										                name => 'NPRD',
										                peer => "$nonprod_server:6557",
										         },
										         {
										                name => 'PROD',
										                peer => "$prod_server:6557",
										         },
										         {
										                name => 'Multi',
										                peer => "$multisite_server:6557",
										         }
										      
										      ],
                                     
                                     name             => 'multiple connector',
                                     verbose          => 0,
                                     timeout          => 5,
                                     keepalive        => 1,
                                     logger           => get_logger(),
                                     query_timeout	=> 5,
				     use_threads 	=> 20,
                                      );
my $log = get_logger();
my $querys;
#########################################################################
if  ( $request =~ /hosts/ ){
$querys = [
	    
    {'query' => "GET hosts\nColumns: name address state as status\n",
     'sub'   => "selectall_arrayref",
     'opt'   => {Slice => 3 }
    },  
];  
}elsif ( $request =~ /services/ ){
$querys = [	
   { 'query' => "GET services\nColumns: description host_name state\n",
     'sub'   => "selectall_arrayref",
     'opt'   => {Slice => 3 }
    },  
];
}elsif ( $request =~ /all/ ){
$querys = [
    { 'query' => "GET services\n",
     'sub'   => "selectall_arrayref",
     'opt'   => {Slice => 1}
    },
];
}


for my $query (@{$querys}) {
    my $sub     = $query->{'sub'};
    my $t0      = [gettimeofday];
    my $stats   = $nl->$sub($query->{'query'}, $query->{'opt'});
    my $elapsed = tv_interval($t0);
    #return Dumper($stats);
    return $stats;
    #print "Query took ".($elapsed)." seconds\n";
}

#end sub
}
#########################################################################

sub add_file {
    my $file = shift;
    push @opt_f, $file;
}

#########################################################################


