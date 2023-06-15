#
# Copyright (c) 2006, 2007 Michael Schroeder, Novell Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program (see the file COPYING); if not, write to the
# Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA
#
################################################################
#
# Open Build Service Configuration
#

package BSConfig;

use Net::Domain;
use Socket;

my $hostname = Net::Domain::hostfqdn() || 'localhost';
# IP corresponding to hostname (only used for $ipaccess); fallback to localhost since inet_aton may fail to resolve at shutdown.
my $ip = quotemeta inet_ntoa(inet_aton($hostname) || inet_aton("localhost"));

my $frontend = 127.0.0.1; # FQDN of the WebUI/API server if it's not $hostname

# If defined, restrict access to the backend servers (bs_repserver, bs_srcserver, bs_service)
our $ipaccess = {
   '^::1$' => 'rw',    # only the localhost can write to the backend
   '^127\..*' => 'rw', # only the localhost can write to the backend
   "^$ip\$" => 'rw',   # Permit IP of FQDN
   "^172.25.3.*" => 'rw',   # back-deepin-main
   '.*' => 'worker',   # build results can be delivered from any client in the network
};

# IP of the WebUI/API Server (only used for $ipaccess)
if ($frontend) {
  my $frontendip = quotemeta inet_ntoa(inet_aton($frontend) || inet_aton("localhost"));
  $ipaccess->{$frontendip} = 'rw' ; # in dotted.quad format
}

# Change also the SLP reg files in /etc/slp.reg.d/ when you touch hostname or port
our $srcserver = "http://172.25.3.1:5352";
#our $reposerver = "http://$hostname:5252";
our $serviceserver = "http://172.25.3.1:5152";
#our $clouduploadserver = "http://$hostname:5452";
#

our @reposervers = ("
	http://172.25.3.2:5252,
");

our $redisserver = "redis://127.0.0.1";
# you can use different ports for worker connections
our $workersrcserver = "http://10.20.64.72:5353";
our $workerreposerver = "http://10.20.64.72:5253";

our $servicedir = "/usr/lib/obs/service/";
#our $servicetempdir = "/srv/obs/service";
#our $serviceroot = "/opt/obs/MyServiceSystem";

# Maximum number of concurrent jobs for source service
#our $service_maxchild = 20;

# optional notification service:
#our $hermesserver = "http://$hostname/hermes";
#our $hermesnamespace = "OBS";
#
# Notification Plugin, multiple plugins supported, separated by space
#our $notification_plugin = "notify_hermes notify_rabbitmq";
#

# Package defaults
our $bsdir = '/srv/obs';
our $bsuser = 'obsrun';
our $bsgroup = 'obsrun';
# user and group for bs_service (if the lxc service wrapper is used, set
# $bsserviceuser to root). If several obs services (e.g., bs_service and
# bs_srcserver) run on the same host, make sure that $bsservicegroup is set
# to $bsgroup.
our $bsserviceuser = 'obsservicerun';
our $bsservicegroup = $bsgroup;
#our $bsquotafile = '/srv/obs/quota.xml';

# Use asynchronus scheduler. This avoids hanging schedulers on remote projects,
# when the network is slow or broken. This will become the default in future
# our $sched_asyncmode = 1;

# Define how the scheduler does a cold start. The default (0) is to request the
# data for all packages, (1) means that only the non-remote packages are fetched,
# (2) means that all of the package data fetches get delayed.
# our $sched_startupmode = 0;

# Disable fdatasync calls, increases the speed, but may lead to data 
# corruption on system crash when the filesystem does not guarantees
# data write before rename.
# It is esp. required on XFS filesystem.
# It is safe to be disabled on ext4 and btrfs filesystems.
#our $disable_data_sync = 1;

# Package rc script / backend communication + log files
our $rundir = "$bsdir/run";
our $logdir = "$bsdir/log";

# optional for non-acl systems, should be set for access control
# 0: trees are shared between projects (built-in default)
# 1: trees are not shared (only usable for new installations)
# 2: new trees are not shared, in case of a missing tree the shared
#    location is also tried (package default)
our $nosharedtrees = 2;

# enable binary release tracking by default for release projects
our $packtrack = [];

# optional: limit visibility of projects for some architectures
#our $limit_projects = {
# "ppc" => [ "openSUSE:Factory", "FATE" ],
# "ppc64" => [ "openSUSE:Factory", "FATE" ],
#};

# optional: allow seperation of releasnumber syncing per architecture
# one counter pool for all ppc architectures, one for i586/x86_64,
# arm archs are seperated and one for the rest in this example
our $relsync_pool = {
 "local" => "local",
 "i586" => "i586",
 "x86_64" => "i586",
 "ppc" => "ppc",
 "ppc64" => "ppc",
 "ppc64le" => "ppc",
 "mips" => "mips",
 "mips64" => "mips",
 "mipsel" => "mipsel",
 "mips64el" => "mipsel",
 "aarch64"  => "arm",
 "aarch64_ilp32"  => "arm",
 "armv4l"  => "arm",
 "armv5l"  => "arm",
 "armv6l"  => "arm",
 "armv6hl" => "arm",
 "armv7l"  => "arm",
 "armv7hl" => "arm",
 "armv5el" => "armv5el", # they do not exist
 "armv6el" => "armv6el",
 "armv7el" => "armv7el",
 "armv8el" => "armv8el",
 "sparcv9" => "sparcv9",
 "sparc64" => "sparcv9",
};

#No extra stage server sync
#our $stageserver = 'rsync://127.0.0.1/put-repos-main';
#our $stageserver_sync = 'rsync://127.0.0.1/trigger-repos-sync';

#additional options for calling rsync in the publisher
#for example "--whole-file" if network faster than disk
#our $rsync_extra_options = "--whole-file";

#No package signing server
our $sign = "/usr/bin/sign";
#Extend sign call with project name as argument "--project $NAME"
#our $sign_project = 1;
#Global sign key 
our $keyfile = "/srv/obs/obs-default-gpg.asc";
our $gpg_standard_key = "/srv/obs/obs-default-gpg.asc";

# Use a special local arch for product building
# our $localarch = "x86_64";

# config options for the bs_worker
#
#our buildlog_maxsize = 500 * 1000000;
#our buildlog_maxidle =   8 * 3600;
#our xenstore_maxsize =  20 * 1000000;
#our gettimeout =         1 * 3600;
#
# run a script to check if the worker is good enough for the job
#our workerhostcheck = 'my_check_script';
# 
# Allow to build as root, exceptions per package
# the keys are actually anchored regexes
# our $norootexceptions = { "my_project/my_package" => 1, "openSUSE:Factory.*/installation-images" => 1 };

# Use old style source service handling
# our $old_style_services = 1;

###
# Optional support to split the binary backend. This can be used on large servers
# to seperate projects for better scalability.
# There is still just one source server, but there can be multiple servers which
# run each repserver, schedulers, dispatcher, warden and publisher
#
# This repo service is the 'home' server for all home:* projects. This and the
# $reposerver setting must be different on the binary backend servers.
# our $partition = 'home';
#
# this defines how the projects are split. All home: projects are hosted
# on an own server in this example. Order is important.
our $partitioning = [
	'.*'    => 'back-deepin-main',
];
#
our $partitionservers = {
        'back-deepin-main' => 'http://172.25.3.2:5252',
};

# host specific configs
my $hostconfig = __FILE__;
$hostconfig =~ s/[^\/]*$/bsconfig.$hostname/;
if (-r $hostconfig) {
  print STDERR "reading $hostconfig...\n";
  require $hostconfig;
}

# For specific build constraints, for example to require a specific
# security level of the workers.
#
#our $dispatch_constraint = sub {
#  my ($job, $worker) = @_;
#
#  return 0 unless (grep {$_ eq "OBS_WORKER_SECURITY_LEVEL_1"} @{$worker->{'hostlabel'} || []});
#  return 1;
#}

# use createrepo_c instead of createrepo. This gets selected via update-alternatives usualy.
#our $createrepo = '/usr/bin/createrepo_c';
# use modifyrepo_c instead of modifyrepo
#our $modifyrepo = '/usr/bin/modifyrepo_c';

# enable service dispatcher
our $servicedispatch = 1;
# max of 4 parallel running services (default)
# our $servicedispatch_maxchild = 4;

# print all messages with a lower level than $debuglevel in addition to the normal log messages
#our $debuglevel = 1;

our $container_registries = {
   'local' => {
     server => $hostname,
     pushserver => 'local:'
   },
#   'staging-registry.example.com' => {
#     server => '',
#     user => '',
#     password => '',
#     repository_base => '',
#   },
#   'hub.docker.com' => {
#     server => '',
#     user => '',
#     password => '',
#     repository_base => '',
#   },
};

our $publish_containers = [
#   # key:   regex to match projid
#   # value: ArrayRef with identifiers for registries configured in $container_registries
#   'SUSE:.*'        => [ 'registry.example.com', 'hub.docker.com' ],
#   '.*:branches:.*' => [ 'staging-registry.example.com' ],
   '.*'             => ['local'],
];


# special options to use for starting containers in run-service-containerized
# our $docker_custom_opt = [];

## Server where mirrored gems could be found - used in services like obs-service-bundle_gems
# our $gems_mirror = '';
#
## Container which should be 'linked' when running "bundle_gems" service
# our $geminabox_container = '';
#

# public cloud uploader configuration
# our $cloudupload_pubkey = "/etc/obs/cloudupload/_pubkey"; # default setting

1;
