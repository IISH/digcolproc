exec { 'apt-get-update':
  command => '/usr/bin/apt-get update',
  onlyif  => "/bin/sh -c '[ ! -f /var/cache/apt/pkgcache.bin ] || /usr/bin/find /etc/apt/* -cnewer /var/cache/apt/pkgcache.bin | /bin/grep . > /dev/null'",
}

package {
  ['unzip', 'vim']:
    ensure => installed;
}

Exec['apt-get-update'] -> Package <| |>

file {
  '/opt/cache/':
    ensure => directory ;
}

class {
  'digcolproc':
    debug                              => 'yes',
    flow_config                        => {

      # Flow 1
      flow1_hotfolders                  =>'/offloader/flow1/',
      flow1_client                      =>'flow1-acc@digcolproc-iish-sto0-acc.iisg.net',
      flow1_access                      =>'open',
      flow1_access_token                =>'.',
      flow1_autoIngestValidInstruction  =>false,
      flow1_notificationEMail           =>'jho@iisg.nl;etu@iisg.nl;lwo@iisg.nl',
      flow1_ftp_connection              =>'ftp://stagingarea-flow1-acc:stagingarea-flow1-acc@10.0.0.100',

      # Flow 2
      flow2_hotfolders                  =>'/offloader/flow2/',
      flow2_client                      =>'flow2-acc@digcolproc-iish-sto0-acc.iisg.net',
      flow2_access                      =>'closed',
      flow2_access_token                =>'3ba02fa9-eb5c-4e87-966f-a048ba9da53e',
      flow2_autoIngestValidInstruction  =>true,
      flow2_notificationEMail           =>'lwo@iisg.nl',
      flow2_ftp_connection              =>'ftp://stagingarea-flow2-acc:stagingarea-flow2-acc@10.0.0.100',

      # Flow 3
      flow3_hotfolders                  =>'/offloader/flow3/',
      flow3_client                      =>'flow3-acc@digcolproc-iish-sto0-acc.iisg.net',
      flow3_access                      =>'closed',
      flow3_access_token                =>'.',
      flow3_autoIngestValidInstruction  =>false,
      flow3_notificationEMail           =>'gcu@iisg.nl;lwo@iisg.nl;digcolproc.jira@socialhistoryservices.org',
      flow3_ftp_connection              =>'ftp://stagingarea-flow3-acc:stagingarea-flow3-acc@10.0.0.100',

      # flow 4, dods
      flow4_hotfolders                  =>'/offloader/flow4/',
      flow4_client                      =>'flow4-acc@digcolproc-iish-sto0-acc.iisg.net',
      flow4_access                      =>'closed',
      flow4_access_token                =>'.',
      flow4_autoIngestValidInstruction  =>false,
      flow4_notificationEMail           =>'lwo@iisg.nl;edr@iisg..nl',
      flow4_ftp_connection              =>'ftp://stagingarea-flow4-acc:stagingarea-flow4-acc@10.0.0.100',

      # Flow 5 access status
      flow5_hotfolders                  =>'/offloader/flow5/access/',
      flow5_client                      =>'flow5-acc@digcolproc-iish-sto0-acc.iisg.net',
      flow5_access                      =>'closed',
      flow5_access_token                =>'.',
      flow5_autoIngestValidInstruction  =>true,
      flow5_notificationEMail           =>'edr@iisg.nl;lwo@iisg.nl',
      flow5_set                         =>'iish.evergreen.biblio',
      flow5_ftp_connection              =>'ftp://stagingarea-flow5-acc:stagingarea-flow5-acc@10.0.0.100',

      # Global settings
      flow_keys                         =>'client autoIngestValidInstruction notificationEMail access access_token ftp_connection',
      mailrelay                         =>'mailrelay2.iisg.nl',
      mail_relay=>'mail1.socialhistoryservices.org',
      mail_user=>'support.socialhistoryservices.org',
      mail_password=>'V0geltj3',
      pidwebserviceEndpoint             =>'https://pid.socialhistoryservices.org/secure/',
      pidwebserviceKey                  =>'ba5f2d4a-caf0-404f-8404-a9dfb6cd8ec1',
      catalog                           =>'http://search.socialhistory.org/Record',
      'or'                              =>'http://disseminate.objectrepository.org',
      oai                               =>'http://api.socialhistoryservices.org/solr/all/oai',
      sru                               =>'http://api.socialhistoryservices.org/solr/all/srw',
      acquisition_database              =>'http://10.0.0.100:8080',
      acquisition_database_access_token =>'ad'

    } ;
  'proftpd':
    proxy_fqdn                      => '10.0.0.100',
    proftpd_conf_server_name        => 'Digcolproc and object repository acceptance server',
    proftpd_conf_masquerade_address => '10.0.0.100',
    proftpd_conf_passive_ports      => '50000 59999';
}



class {
  '::mysql::server':
    databases       =>{ 'ad'  => {
      ensure         =>'present',
      charset        => 'utf8'
    }
    },
    users           => {
      'ad@localhost' => {
        ensure=>present,
        password_hash=>'*3C4CAC5F9299DA5727380393F02B0E30E12C376F'
      },
      'ad@10.0.0.1' => {
        ensure=>present,
        password_hash=>'*3C4CAC5F9299DA5727380393F02B0E30E12C376F'
      },
      'ad@10.0.0.100' => {
        ensure=>present,
        password_hash=>'*3C4CAC5F9299DA5727380393F02B0E30E12C376F'
      }
    },
    grants          => {
      'ad@localhost/ad.*'=> {
        ensure=>present,
        options=>'GRANT',
        privileges=> ['SELECT', 'INSERT', 'UPDATE', 'DELETE', 'ALTER'],
        table=>'ad.*',
        user=>'ad@localhost'
      },
      'ad@10.0.0.1/ad.*'=> {
        ensure=>present,
        options=>'GRANT',
        privileges=> ['SELECT', 'INSERT', 'UPDATE', 'DELETE', 'ALTER'],
        table=>'ad.*',
        user=>'ad@10.0.0.1'
      },
      'ad@10.0.0.100/ad.*'=> {
        ensure=>present,
        options=>'GRANT',
        privileges=> ['SELECT', 'INSERT', 'UPDATE', 'DELETE', 'ALTER'],
        table=>'ad.*',
        user=>'ad@10.0.0.100'
      }
    },
    override_options=> {
      mysqld=> {
        bind_address=>'10.0.0.100'
      }
    }
}

class {
  'tomcat':
    java_opts   => '-server -Xms1024M -Xmx1024M -Dacquisition.properties=/etc/tomcat7/application.properties -Djavax.net.ssl.trustStorePassword=changeit -Djavax.net.ssl.trustStore=/etc/tomcat7/cacerts',
    log_level   =>'warning',
    properties  => {
      'ingestDepot.contentType.fileIdentificationReport'=>'text/plain',

      'dataSource.url'=>'jdbc:mysql://10.0.0.100:3306/ad',
      'dataSource.username'=>'ad',
      'dataSource.password'=>'ad',

      'grails.plugin.springsecurity.ldap.context.server'=>'ldap://ds0.socialhistoryservices.org',
      'grails.plugin.springsecurity.ldap.context.managerDn'=>'cn=admin,dc=socialhistoryservices,dc=org',
      'grails.plugin.springsecurity.ldap.context.managerPassword'=>'G3tL0st',
      'grails.plugin.springsecurity.ldap.search.base'=>'ou=users,dc=socialhistoryservices,dc=org',

      'role_admin'=>'kerim,mmu,jzw,gcu,lvwouw',
      'role_user'=>'bhi,hsa,mvh,fdj,rba,eef vermeij,zulfikar.ozdogan,eko',

      'grails.mail.host'=>'mail1.socialhistoryservices.org',
      'grails.mail.port'=>'25',
      'grails.mail.username'=>'support.socialhistoryservices.org',
      'grails.mail.password'=>'V0geltj3',

      'ingestDepot.ftp.secure'=>'true',
      'ingestDepot.ftp.isImplicit'=>'false',
      'ingestDepot.ftp.enterLocalPassiveMode'=>'true',
      'ingestDepot.ftp.host'=>'10.0.0.100',
      'ingestDepot.ftp.port'=>'21',
      'ingestDepot.ftp.username'=>'flow3-owner',
      'ingestDepot.ftp.password'=>'flow3-owner',

      'grails.serverURL'=>'http://10.0.0.100:8080',
      'access_token'=>'ad'

    }
}

tomcat::add-war {
  'ad':
}

trigger::add_trigger_war {
  'ad':
    bamboo_key          => 'AD-TEST',
    filename            => 'ad-1.0.war',
    bamboo_tag_version  => '1.0',
    bamboo_build_version=> 'latestSuccessful',
    location            =>'/opt/ad/';
}

file {
  ['/offloader/',
    '/offloader/flow1/', '/offloader/flow1/10622/',
    '/offloader/flow2/', '/offloader/flow2/10622/',
    '/offloader/flow3/', '/offloader/flow3/10622/',
    '/offloader/flow4/', '/offloader/flow4/10622/',
    '/offloader/flow5/', '/offloader/flow5/10622/',
    '/stagingarea/',
    '/stagingarea/10622/',
  ]:
    owner    => '10622',
    group    => 10622,
    ensure   => directory ;
  '/offloader/flow1/10622/offloader-flow1-acc/':
    owner     => 'offloader-flow1-acc',
    group     => 10622,
    ensure    => directory ;
  '/offloader/flow2/10622/offloader-flow2-acc/':
    owner     => 'offloader-flow2-acc',
    group     => 10622,
    ensure    => directory ;
  '/offloader/flow3/10622/offloader-flow3-acc/':
    owner     => 'offloader-flow3-acc',
    group     => 10622,
    ensure    => directory ;
  '/offloader/flow4/10622/offloader-flow4-acc/':
    owner     => 'offloader-flow4-acc',
    group     => 10622,
    ensure    => directory ;
  '/offloader/flow5/10622/offloader-flow5-acc/':
    owner     => 'offloader-flow5-acc',
    group     => 10622,
    ensure    => directory ;
  '/stagingarea/10622/stagingarea-flow1-acc/':
    owner     => 'stagingarea-flow1-acc',
    group     => 10622,
    ensure    => directory ;
  '/stagingarea/10622/stagingarea-flow2-acc/':
    owner     => 'stagingarea-flow2-acc',
    group     => 10622,
    ensure    => directory ;
  '/stagingarea/10622/stagingarea-flow3-acc/':
    owner     => 'stagingarea-flow3-acc',
    group     => 10622,
    ensure    => directory ;
  '/stagingarea/10622/stagingarea-flow4-acc/':
    owner     => 'stagingarea-flow4-acc',
    group     => 10622,
    ensure    => directory ;
  '/stagingarea/10622/stagingarea-flow5-acc/':
    owner     => 'stagingarea-flow5-acc',
    group     => 10622,
    ensure    => directory ;
}->user {
  'offloader-flow3-owner':
    ensure      => present,
    managehome  => true,
    home        =>'/offloader/flow3/10622/',
    shell       => '/bin/sh';
  'offloader-flow1-acc':
    ensure      => present,
    home        =>'/offloader/flow1/10622/offloader-flow1-acc/',
    managehome  => true,
    shell       => '/bin/sh';
  'offloader-flow2-acc':
    ensure      => present,
    home        =>'/offloader/flow2/10622/offloader-flow2-acc/',
    managehome  => true,
    shell       => '/bin/sh';
  'offloader-flow3-acc':
    ensure      => present,
    home        =>'/offloader/flow3/10622/offloader-flow3-acc/',
    managehome  => true,
    shell       => '/bin/sh';
  'offloader-flow4-acc':
    ensure      => present,
    home        =>'/offloader/flow4/10622/offloader-flow4-acc/',
    managehome  => true,
    shell       => '/bin/sh';
  'offloader-flow5-acc':
    ensure      => present,
    home        =>'/offloader/flow5/10622/offloader-flow5-acc/',
    managehome  => true,
    shell       => '/bin/sh';

  'stagingarea-flow1-acc':
    ensure      => present,
    home        =>'/stagingarea/10622/stagingarea-flow1-acc/',
    managehome  => true,
    shell       => '/bin/sh';
  'stagingarea-flow2-acc':
    ensure      => present,
    home        => '/stagingarea/10622/stagingarea-flow2-acc/',
    shell       => '/bin/sh';
  'stagingarea-flow3-acc':
    ensure      => present,
    home        =>'/stagingarea/10622/stagingarea-flow3-acc/',
    managehome  => true,
    shell       => '/bin/sh';
  'stagingarea-flow4-acc':
    ensure      => present,
    home        =>'/stagingarea/10622/stagingarea-flow4-acc/',
    managehome  => true,
    shell       => '/bin/sh';
  'stagingarea-flow5-acc':
    ensure      => present,
    home        =>'/stagingarea/10622/stagingarea-flow5-acc/',
    managehome  => true,
    shell       => '/bin/sh';
}
