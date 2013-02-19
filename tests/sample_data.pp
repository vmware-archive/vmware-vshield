$vcenter = {
  'username' => 'root',
  'password' => 'vmware',
  'server'   => '192.168.1.1',
  'options'  => { 'insecure' => true }
}

$vshield= {
  'username' => 'admin',
  'password' => 'default',
  'server'   => '192.168.1.2',
}

$dc1 = {
  'name' => 'testdc',
  'path' => '/testdc',
}

$cluster1 = {
  'name' => 'clu1',
}

$esx1 = {
  'username' => 'root',
  'password' => 'password',
  'hostname' => '192.168.1.100',
}

$edge = {
  'name' => 'dmz',
  'fqdn' => 'dmz.edge.lan',
  'vnics' => [
    { name      => 'uplink-test',
      portgroup => 'd5p0pod-cus-pg-14',
      type      => 'Uplink',
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
    { name       =>'internal-1',
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
}

$default_route = { gatewayAddress => '69.194.136.1', vnic => 'uplink-test' },
$static_routes = [
  { network => '10.0.32.0/24', nextHop => '10.10.0.1', vnic => 'internal-1' },
]
