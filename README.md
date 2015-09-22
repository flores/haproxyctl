HAProxyCTL
==========

This is a simple wrapper to make life with HAProxy a little more convenient.

* Acts as an init script for start, stop, reload, restart, etc
* Leverages 'socket' to enable and disable servers on the fly
* Formats server weight and backends in a readable way
* Provides Nagios and Cloudkick health checks
* chkconfig/service-able for Redhat folk

[Here](http://lo.ladevops.org/haproxyctl) is a presentation about it.  Hit space to advance slides.


Installation
------------

On most UNIX, assuming HAProxy is in the $PATH:
<pre>
git clone git@github.com:flores/haproxyctl.git
ln -s haproxyctl/haproxyctl /etc/init.d/haproxyctl
</pre>

For chkconfig/RedHat/Centos, add:
<pre>
chkconfig --add haproxyctl
</pre>

Or if have RubyGems, just gem install it!
<pre>
gem install haproxyctl
</pre>

Or if you are on Debian, just install haproxy with apt-get!
<pre>
apt-get install haproxyctl
</pre>

There is also an HAProxy source installation script.  This installs not only the steps above but also HAProxy itself.

Options
-----------------
<pre>
# ./haproxyctl help
usage: ./haproxyctl <argument>
  where argument can be:
    start: start haproxy unless it is already running
    stop: stop an existing haproxy
    restart: immediately shutdown and restart
    reload: gracefully terminate existing connections, reload /etc/haproxy/haproxy.cfg
    status: is haproxy running?  on what ports per lsof?
    configcheck: check /etc/haproxy/haproxy.cfg
    nagios: nagios-friendly status for running process and listener
    cloudkick: cloudkick.com-friendly status and metric for connected users
    show health: show status of all frontends and backend servers
    show backends: show status of backend pools of servers
    enable all <server>: re-enable a server previously in maint mode on multiple backends
    disable all <server>: disable a server from every backend it exists
    enable all EXCEPT <server>: like 'enable all', but re-enables every backend except for <server>
    disable all EXCEPT <server>: like 'disable all', but disables every backend except for <server>
    clear counters: clear max statistics counters (add 'all' for all counters)
    help: this message
    prompt: toggle interactive mode with prompt
    quit: disconnect
    show info: report information about the running process
    show stat [counter...]: report counters for each proxy and server
    show errors: report last request and response errors for each proxy
    show sess [id]: report the list of current sessions or dump this session
    get weight: report a server's current weight
    set weight: change a server's weight
    set timeout: change a timeout setting
    disable server: set a server in maintenance mode
    enable server: re-enable a server that was previously in maintenance mode
</pre>

Examples
--------

## Status check
<pre>
  ./haproxyctl status
  haproxy is running on pid 23162.
  these ports are used and guys are connected:
  173.255.194.115:www->98.154.245.132:52025 (ESTABLISHED)
  173.255.194.115:www->97.89.32.126:52043 (ESTABLISHED)
  *:www (LISTEN)
  *:53093 
  173.255.194.115:www->83.39.69.106:19338 (ESTABLISHED)
</pre>

## Errors to the backend servers
<pre>
  ./haproxyctl "show errors"
  [04/Feb/2011:21:05:59.542] frontend http (#1): invalid request
    src 209.59.188.205, session #39574, backend <NONE> (#-1), server <NONE> (#-1)
    request length 125 bytes, error at position 27:
 
    00000  GET /logs/images/stuff/someurl
    00070+  HTTP/1.1\r\n
    00081  Host: wet.biggiantnerds.com\r\n
    00110  Accept: */*\r\n
    00123  \r\n
</pre>
## Human readable health check
<pre>
  ./haproxyctl "show health"
    pxname      svname       status  weight
  http        FRONTEND                  OPEN       
  sinatra     sinatra_downoi            DOWN    1  
  sinatra     sinatra_rindica           DOWN    1  
  sinatra     sinatra_guinea            UP      1  
  sinatra     BACKEND                   UP      1  
  ei          guinea                    UP      1  
  ei          belem                     UP      1  
  ei          BACKEND                   UP      1  
  drop        guinea                    UP      1  
  drop        belem                     UP      1  
  drop        BACKEND                   UP      1  
  apache      guinea                    UP      1  
  apache      belem                     UP      1  
  apache      BACKEND                   UP      1  
  static      ngnix_downoi              UP      1  
  static      ngnix_petite              UP      1  
  static      ngnix_rindica             UP      1  
  static      nginx_stellatus           UP      1  
  static      nginx_belem               UP      1  
  static      nginx_petite              DOWN    1  
  static      apache_guinea             UP      1  
  static      BACKEND                   UP      6  
  ssh         localhost                 UP      1  
  ssh         BACKEND                   UP      1  

  ./haproxyctl "show backends"
  contact     BACKEND                   UP      1
  alpha       BACKEND                   DOWN    0
  sinatra     BACKEND                   DOWN    0
  python      BACKEND                   UP      1
  mobile      BACKEND                   DOWN    0
  ei          BACKEND                   UP      1
  showoff     BACKEND                   UP      1
  drop        BACKEND                   UP      1
  cheap       BACKEND                   UP      1
  apache      BACKEND                   UP      1
  static      BACKEND                   UP      1
  ssh         BACKEND                   UP      1
</pre>

## Disable servers on the fly  
<pre>
  ./haproxyctl "disable server static/nginx_belem"
  
  ./haproxyctl "show health" |grep nginx_belem
  static      nginx_belem               MAINT   1 
</pre>  
## Graceful reloads
<pre>
  ./haproxyctl reload
  gracefully stopping connections on pid 23162...
  checking if connections still alive on 23162...
  reloaded haproxy on pid 1119
</pre>  
## Cloudkick/Nagios checks with graph-friendly output for queue size, total connections, etc
<pre>
  ./haproxyctl cloudkick    
  status ok haproxy is running
  metric connections int 12
  metric http_FRONTEND_request_rate int 45
  metric http_FRONTEND_health_check_duration int 45
  metric sinatra_sinatra_guinea_health_check_duration int 4
  metric sinatra_BACKEND_health_check_duration int 4
  metric mobile_sinatra_mobile_health_check_duration int 2
  metric mobile_BACKEND_health_check_duration int 2
  metric ei_guinea_health_check_duration int 4
  metric ei_BACKEND_health_check_duration int 4
  metric drop_guinea_total_requests gauge 1
  metric drop_guinea_health_check_duration int 6
  metric drop_BACKEND_total_requests gauge 1
  metric drop_BACKEND_health_check_duration int 6
  metric apache_guinea_health_check_duration int 41
  metric apache_BACKEND_health_check_duration int 41
  metric static_ngnix_downoi_total_requests gauge 472
  metric static_ngnix_downoi_health_check_duration int 7
  metric static_ngnix_petite_total_requests gauge 475
  metric static_ngnix_petite_health_check_duration int 8
  metric static_ngnix_rindica_total_requests gauge 457
  metric static_ngnix_rindica_health_check_duration int 8
  metric static_nginx_stellatus_total_requests gauge 470
  metric static_nginx_stellatus_health_check_duration int 7
  metric static_nginx_belem_total_requests gauge 460
  metric static_nginx_belem_health_check_duration int 8
  metric static_apache_guinea_total_requests gauge 449
  metric static_apache_guinea_health_check_duration int 14
  metric static_BACKEND_total_requests gauge 2783
  metric static_BACKEND_health_check_duration int 45
</pre>
## does normal things like checks if a process is running before starting it...
<pre>
  ./haproxyctl start    
  ./haproxyctl:35: haproxy is already running on pid 20317! (RuntimeError)
  
  ./haproxyctl restart
  stopping existing haproxy on pid 20317...
  waiting a ms...
  checking if haproxy is still running...
  starting haproxy...
  done.  running on pid 20348
</pre>  
## keeps all the regular UNIX socket stuff
<pre>
  ./haproxyctl "show stat"
  pxname,svname,qcur,qmax,scur,smax,slim,stot,bin,bout,dreq,dresp,ereq,econ,eresp,wretr,wredis,status,weight,act,bck,chkfail,chkdown,lastchg,downtime,qlimit,pid,iid,sid,throttle,lbtot,tracked,type,rate,rate_lim,rate_max,check_status,check_code,check_duration,hrsp_1xx,hrsp_2xx,hrsp_3xx,hrsp_4xx,hrsp_5xx,hrsp_other,hanafail,req_rate,req_rate_max,req_tot,cli_abrt,srv_abrt,
  http,FRONTEND,,,3,82,2000,39585,47067637,12818945246,0,0,1465,,,,,OPEN,,,,,,,,,1,1,0,,,,0,0,0,59,,,,0,91460,13125,4115,305,73,,0,131,109078,,,
  sinatra,sinatra_downoi,0,0,0,1,,791,452469,2258353,,0,,0,0,0,0,UP,1,1,0,60,13,304106,59545,,1,2,1,,791,,2,0,,1,L4OK,,46,0,736,0,40,15,0,0,,,,0,0,
  sinatra,sinatra_rindica,0,0,0,1,,795,450488,2333534,,0,,0,0,3,1,UP,1,1,0,68,10,347679,52849,,1,2,2,,792,,2,0,,1,L4OK,,46,0,753,0,28,10,0,0,,,,0,0,
  sinatra,sinatra_guinea,0,0,0,7,,638,360994,1046343,,0,,0,258,1,0,UP,1,1,0,4,4,1892969,72241,,1,2,3,,637,,2,0,,3,L4OK,,0,0,317,0,13,11,0,0,,,,0,0,
  sinatra,BACKEND,0,0,0,7,0,2219,1263951,5638230,0,0,,0,299,4,1,UP,3,3,0,,0,2144680,0,,1,2,0,,2220,,1,0,,3,,,,0,1806,0,81,291,41,,,,,0,0,
  ei,guinea,0,0,0,4,,3514,2067456,68408884,,0,,0,0,0,0,UP,1,1,0,6,1,2142278,70,,1,3,1,,3514,,2,0,,11,L4OK,,0,0,3060,323,131,0,0,0,,,,3,0,
  ei,belem,0,0,0,0,,0,0,0,,0,,0,0,0,0,UP,1,0,1,28,7,259858,1274,,1,3,2,,0,,2,0,,0,L4OK,,43,0,0,0,0,0,0,0,,,,0,0,
  ei,BACKEND,0,0,0,4,0,3514,2067456,68408884,0,0,,0,0,0,0,UP,1,1,1,,0,2144680,0,,1,3,0,,3514,,1,0,,11,,,,0,3060,323,131,0,0,,,,,3,0,
  drop,guinea,0,0,0,2,,1042,634412,15327695,,0,,0,0,0,0,UP,1,1,0,5,1,2142277,70,,1,4,1,,1042,,2,0,,5,L4OK,,0,0,935,28,79,0,0,0,,,,2,0,
  drop,belem,0,0,0,0,,0,0,0,,0,,0,0,0,0,UP,1,0,1,42,7,259855,958,,1,4,2,,0,,2,0,,0,L4OK,,44,0,0,0,0,0,0,0,,,,0,0,
  drop,BACKEND,0,0,0,2,0,1042,634412,15327695,0,0,,0,0,0,0,UP,1,1,1,,0,2144680,0,,1,4,0,,1042,,1,0,,5,,,,0,935,28,79,0,0,,,,,2,0,
  apache,guinea,0,0,0,3,,3781,3733003,19959026,,0,,0,0,0,0,UP,1,1,0,4,1,2142276,70,,1,5,1,,3781,,2,0,,5,L4OK,,0,0,3267,304,208,2,0,0,,,,2,0,
  apache,belem,0,0,0,1,,1,379,528,,0,,0,0,0,0,UP,1,0,1,41,7,259854,1023,,1,5,2,,1,,2,0,,1,L4OK,,43,0,0,0,1,0,0,0,,,,0,0,
  apache,BACKEND,0,0,0,3,0,3782,3733382,19959554,0,0,,0,0,0,0,UP,1,1,1,,0,2144680,0,,1,5,0,,3782,,1,0,,5,,,,0,3267,304,209,2,0,,,,,2,0,
  static,ngnix_downoi,0,0,0,10,,12665,4970818,1883260969,,0,,0,4,25,5,UP,1,1,0,72,10,303928,61648,,1,6,1,,12640,,2,0,,10,L4OK,,46,0,10671,1656,307,0,0,0,,,,1167,4,
  static,ngnix_petite,0,0,0,10,,13052,5141468,2033386644,,0,,1,5,13,3,UP,1,1,0,63,6,347401,11776,,1,6,2,,13039,,2,0,,10,L4OK,,46,0,10988,1694,352,0,0,0,,,,1223,4,
  static,ngnix_rindica,0,0,0,10,,12736,5007655,2002399557,,0,,0,8,20,5,UP,1,1,0,64,10,347499,55375,,1,6,3,,12716,,2,0,,10,L4OK,,45,0,10736,1649,321,0,0,0,,,,1146,3,
  static,nginx_stellatus,0,0,0,10,,15142,6017327,2194578425,,0,,0,7,0,0,UP,1,1,0,8,1,1555595,786,,1,6,4,,15142,,2,0,,10,L4OK,,42,0,12932,1844,364,0,0,0,,,,1253,8,
  static,nginx_belem,0,0,0,10,,15227,6075157,2231761586,,0,,0,5,1,0,UP,1,1,0,10,1,1555573,787,,1,6,5,,15226,,2,0,,12,L4OK,,44,0,12981,1882,362,0,0,0,,,,1227,4,
  static,nginx_petite,0,0,0,0,,0,0,0,,0,,0,0,0,0,DOWN,1,1,0,0,1,2144610,2144610,,1,6,6,,0,,2,0,,0,L4CON,,21000,0,0,0,0,0,0,0,,,,0,0,
  static,apache_guinea,0,0,0,10,,24091,9895320,2263895160,,0,,0,0,0,0,UP,1,1,0,2,0,2144680,0,,1,6,7,,24091,,2,0,,100,L4OK,,0,0,20593,3038,459,0,0,0,,,,1241,0,
  static,BACKEND,0,0,0,60,0,92841,37107745,12609282341,0,0,,1,29,59,13,UP,6,6,0,,0,2144680,0,,1,6,0,,92854,,1,0,,131,,,,0,78901,11763,2165,12,0,,,,,7257,23,
  ssh,localhost,0,0,0,3,,122,54524,291662,,0,,0,0,0,0,UP,1,1,0,0,0,2144680,0,,1,7,1,,122,,2,0,,10,L4OK,,0,0,121,0,1,0,0,0,,,,0,0,
  ssh,BACKEND,0,0,0,3,0,122,54524,291662,0,0,,0,0,0,0,UP,1,1,0,,0,2144680,0,,1,7,0,,122,,1,0,,10,,,,0,121,0,1,0,0,,,,,0,0,
</pre>
### Extends stat command to print only counters supplied as arguments
<pre>
  ./haproxyctl "show stat qcur qmax"
  http,FRONTEND,,
  sinatra,sinatra_downoi,0,0
  sinatra,sinatra_rindica,0,0
  sinatra,sinatra_guinea,0,0
  sinatra,BACKEND,0,0
  ei,guinea,0,0
  ei,belem,0,0
  ei,BACKEND,0,0
  drop,guinea,0,0
  drop,belem,0,0
  drop,BACKEND,0,0
  apache,guinea,0,0
  apache,belem,0,0
  apache,BACKEND,0,0
  static,ngnix_downoi,0,0
  static,ngnix_petite,0,0
  static,ngnix_rindica,0,0
  static,nginx_stellatus,0,0
  static,nginx_belem,0,0
  static,nginx_petite,0,0
  static,apache_guinea,0,0
  static,BACKEND,0,0
  ssh,localhost,0,0
  ssh,BACKEND,0,0
</pre>

## Enable or disable a target server from every backend it appears.
<pre>
  ./haproxyctl "show health"
  # pxname        svname               status  weight
  http            FRONTEND             OPEN       
  sinatra         sinatra_downoi       DOWN    1  
  sinatra         sinatra_rindica      DOWN    1  
  sinatra         sinatra_guinea       UP      1  
  sinatra         BACKEND              UP      1  
  ei              guinea               UP      1  
  ei              BACKEND              UP      1  
  drop            guinea               UP      1  
  drop            BACKEND              UP      1  
  apache          guinea               UP      1  
  apache          BACKEND              UP      1  
  static          ngnix_downoi         UP      1  
  static          ngnix_petite         UP      1  
  static          ngnix_rindica        UP      1  
  static          nginx_stellatus      UP      1  
  static          nginx_belem          UP      1  
  static          nginx_petite         MAINT   1  
  static          apache_guinea        UP      1  
  static          BACKEND              UP      6  
  ssh             localhost            UP      1  
  ssh             BACKEND              UP      1  
  
                                                 
  ./haproxyctl "disable all guinea"
  ./haproxyctl "show health"
    pxname        svname               status  weight
  http            FRONTEND             OPEN       
  sinatra         sinatra_downoi       DOWN    1  
  sinatra         sinatra_rindica      DOWN    1  
  sinatra         sinatra_guinea       UP      1  
  sinatra         BACKEND              UP      1  
  ei              guinea               MAINT   1  
  ei              BACKEND              DOWN    0  
  drop            guinea               MAINT   1  
  drop            BACKEND              DOWN    0  
  apache          guinea               MAINT   1  
  apache          BACKEND              DOWN    0  
  static          ngnix_downoi         UP      1  
  static          ngnix_petite         UP      1  
  static          ngnix_rindica        UP      1  
  static          nginx_stellatus      UP      1  
  static          nginx_belem          UP      1  
  static          nginx_petite         UP      1  
  static          apache_guinea        UP      1  
  static          BACKEND              UP      1  
  ssh             localhost            UP      1  
  ssh             BACKEND              UP      1  
</pre>
  
## Has an EXCEPT flag, too                                                 
<pre>
  ./haproxyctl "enable all EXCEPT apache_guinea"
  ./haproxyctl "show health"
    pxname        svname               status  weight
  http            FRONTEND             OPEN       
  sinatra         sinatra_downoi       DOWN    1  
  sinatra         sinatra_rindica      DOWN    1  
  sinatra         sinatra_guinea       UP      1  
  sinatra         BACKEND              UP      1  
  ei              guinea               UP      1  
  ei              BACKEND              UP      1  
  drop            guinea               UP      1  
  drop            BACKEND              UP      1  
  apache          guinea               UP      1  
  apache          BACKEND              UP      1  
  static          ngnix_downoi         UP 1/2  1  
  static          ngnix_petite         UP 1/2  1  
  static          ngnix_rindica        UP 1/2  1  
  static          nginx_stellatus      UP 1/2  1  
  static          nginx_belem          UP 1/2  1  
  static          nginx_petite         UP 1/2  1  
  static          apache_guinea        UP      1  
  static          BACKEND              UP      7  
  ssh             localhost            UP      1  
  ssh             BACKEND              UP      1 
</pre>

Contributors
------------

- [flores aka `flores`](https://github.com/flores)
- [Scott Gonyea aka `sgonyea`](https://github.com/sgonyea)
- [Ben Lovett aka `blovett`](https://github.com/blovett)
- [John A. Barbuto aka `jbarbuto`](https://github.com/jbarbuto)
- [Till Klampaeckel aka `till`](https://github.com/till)
- [Erik Osterman aka `osterman`](https://github.com/osterman)
- [Martin Hald aka `mhald`](https://github.com/mhald)
- [deniedboarding](https://github.com/deniedboarding)
- [Aaron Blew aka `blewa`](https://github.com/blewa)
- [Nick Griffiths aka `nicobrevin`](https://github.com/nicobrevin)
- [Florian Holzhauer aka `fh`](https://github.com/fh)
- [Jonas Genannt aka `hggh`](https://github.com/hggh)
- [Grant Shively aka `gshively11`](https://github.com/gshively11)

Non-current HAProxy versions 
------------
Be aware that HAProxy below version 1.4 does not support many of the 
options of haproxyctl.


License
-----------------

This code is released under the MIT License.  You should feel free to do whatever you want with it.  
