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

vshield_dns { $edge['name']:
  dns_servers => [ '10.0.0.1', '10.0.0.2' ],
  enabled     => 'true',
  transport   => Transport['vshield'],
}
