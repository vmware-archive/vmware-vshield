import 'data.pp'

transport { 'vshield':
  username => $vshield['username'],
  password => $vshield['password'],
  server   => $vshield['server'],
}

transport { 'vcenter':
  username => $vcenter['username'],
  password => $vcenter['password'],
  server   => $vcenter['server'],
  options  => $vcenter['options'],
}

vshield_ipset { 'web1':
  value      => [ '10.10.10.1' ],
  scope_type => 'edge',
  scope_name => $edge['name'],
  transport  => Transport['vshield'],
}

vshield_application_group { 'puppet_and_smtp':
  ensure             => present,
  application_member => [ 'puppet', 'SMTP' ],
  scope_type         => 'edge',
  scope_name         => $edge['name'],
  transport          => Transport['vshield'],
}

vshield_firewall {'dmz-to-puppet':
  ensure              => present,
  source              => [ 'demo'],
  destination         => [ 'web1' ],
  service_application => [ 'HTTP' ],
  action              => 'accept',
  #log                 => 'false',
  scope_name          => $edge['name'],
  require             => Vshield_ipset['web1'],
  transport           => Transport['vshield'],
}

vshield_firewall {'service_group_test':
  ensure              => present,
  source              => [ 'demo'],
  destination         => [ 'web1' ],
  service_application => [ 'HTTPS' ],
  service_group       => [ 'puppet_and_smtp' ],
  action              => 'accept',
  #log                 => 'false',
  scope_name          => $edge['name'],
  require             => [ Vshield_ipset['web1'], Vshield_application_group['puppet_and_smtp'] ],
  transport           => Transport['vshield'],
}
