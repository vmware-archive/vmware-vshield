   transport { 'vshield':
       username => 'admin',
       password => 'default',
       server   => 'd5p0tlm-mgmt-vsm0.cso.vmware.com',
   }

   transport { 'vcenter':
       username => 'root',
       password => 'vmware',
       server   => 'd5p0tlm-mgmt-vc0.cso.vmware.com',
   }

   vshield_syslog { 'd5p0tlm-mgmt-vsm0.cso.vmware.com':
       server_info => 'd5p0tlm-mgmt-netsvc-a.cso.vmware.com:514',
       transport   => Transport['vshield'],
   } 

   #vshield_global_config { 'd5p0tlm-mgmt-vc0.cso.vmware.com':
   #    vc_info   => {
   #        ip_address => 'd5p0tlm-mgmt-vc0.cso.vmware.com',
   #        user_name  => 'root',
   #        password   => 'vmware',
   #    },
   #    time_info => { 'ntp_server' => 'd5p0tlm-mgmt-netsvc-a.cso.vmware.com' },
   #    dns_info  => { 'primary_dns' => '10.255.21.11' },
   #    transport => Transport['vshield'],
   #}

   vshield_edge { 'd5p0tlm-mgmt-vsm0.cso.vmware.com:d5p0v1mgmt-vse-pub':
       ensure           => present,
       datacenter_name  => 'd5p0',
       compute          => 'd5p0mgmt',
       enable_aesni     => false,
       enable_fips      => false,
       enable_tcp_loose => false,
       vse_log_level    => 'info',
       fqdn             => "d5p0v1mgmt-vse-pub.cso.vmware.com",
       #firewall         => {
       #    default_policy => {
       #        action => 'deny',
       #        logging_enabled => false,
       #    }
       #},
       vnics      => [
           {  name       => 'uplink-test', 
              portgroup => 'd5p0pod-cus-pg-14',
              type       => 'Uplink',
              is_connected => 'true',
              address_groups => { 
                'addressGroup' => {
                  'primaryAddress' => '69.194.136.20',
                  'secondaryAddresses' => [
                     { 'ipAddress' => '69.194.136.21'},
                     { 'ipAddress' => '69.194.136.22'},
                  ],
                  'subnetMask' => '255.255.255.128',
                },
              },
           },
           {  name       =>'internal-1',
              portgroup => 'd5p0v1-dmz-pg-60',
              type       => 'Internal',
              is_connected => 'true',
              address_groups => { 
                'addressGroup' => {
                  'primaryAddress' => '10.10.0.20',
                  'secondaryAddresses' => [
                    { 'ipAddress' => '10.10.0.21' },
                    { 'ipAddress' => '10.10.0.22' },
                  ],
                  'subnetMask' => '255.255.255.192',
                },
              },
           },
       ],
       transport  => Transport['vshield'],
   }
