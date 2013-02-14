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

vshield_application { 'puppet':
  ensure               => present,
  application_protocol => 'TCP',
  value                => [ '8140' ],
  scope_type           => 'edge',
  scope_name           => $edge['name'],
  transport            => Transport['vshield'],
}
