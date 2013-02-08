transport { 'vshield':
  username => 'admin',
  password => 'default',
  server   => 'd5p0tlm-mgmt-vsm0.cso.vmware.com',
}

transport { 'vcenter':
  username => 'root',
  password => 'vmware',
  server   => 'd5p0tlm-mgmt-vsm0.cso.vmware.com',
}

vshield_loadbalancer { 'd5p0v1mgmt-vse-pub':
  enabled   => true,
  transport => Transport['vshield'],
}->

vshield_loadbalancer_pool { 'pool1':
  ensure     => present,
  scope_name => 'd5p0v1mgmt-vse-pub',
  service_port => [ 
                   { protocol        => 'HTTP', 
                     algorithm       => 'ROUND_ROBIN',
                     port            => 80,
                     healthCheckPort => 80,
                     healthCheck     => 
                               { mode => HTTP,
                                 healthThreshold   => 2,
                                 unHealthThreshold => 3,
                                 interval          => 5,
                                 uri               => '/',
                                 timeout           => 15,
                               },
                   },
                   { protocol        => 'HTTPS', 
                     algorithm       => 'ROUND_ROBIN',
                     port            => 443,
                     healthCheckPort => 443,
                     healthCheck     => 
                               { mode => SSL,
                                 healthThreshold   => 2,
                                 unHealthThreshold => 3,
                                 interval          => 5,
                                 uri               => '/',
                                 timeout           => 15,
                               },
                   },
                  ],
  member       => [
                   { ipAddress   => '1.1.1.1',
                     weight      => '1',
                     servicePort => {
                                      protocol => 'HTTP',
                                      port     => 80,
                                      healthCheckPort => 80,
                                      healthCheck => { interval => 1 }
                                    }
                   },
                   { ipAddress   => '1.1.1.2',
                     weight      => '1',
                     servicePort => {
                                      protocol => 'HTTP',
                                      port     => 80,
                                      healthCheckPort => 80,
                                      healthCheck => { interval => 1 }
                                    }
                   },
                  ],
  transport  => Transport['vshield'],
}->

vshield_loadbalancer_vip { 'vip1':
  ensure              => present,
  scope_name          => 'd5p0v1mgmt-vse-pub',
  ip_address          => '69.194.136.21',
  application_profile => [
                           { protocol => HTTP,
                             port     => 80,
                             persistence => { method => COOKIE,
                                              cookieName => JSESSIONID,
                                              cookieMode => INSERT,
                             },
                           },
                         ],
  pool                => 'pool1',
  require             => Vshield_loadbalancer_pool['pool1'],

  transport  => Transport['vshield'],
}
