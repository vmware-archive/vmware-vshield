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
    { name          => 'uplink-test',
      portgroupName => 'd5p0pod-cus-pg-14',
      type          => 'uplink',
      isConnected   => true,
      addressGroups => {
        'addressGroup' => {
          'primaryAddress' => '69.194.136.20',
          'secondaryAddresses' => {
            'ipAddress' => [ '69.194.136.21', '69.194.136.22' ],
          },
          'subnetMask' => '255.255.255.128',
        },
      },
    },
    { name          =>'internal-1',
      portgroupName => 'd5p0v1-dmz-pg-60',
      type          => 'internal',
      isConnected   => true,
      addressGroups => {
        'addressGroup' => {
          'primaryAddress' => '10.10.0.20',
          'secondaryAddresses' => {
            'ipAddress' => [ '10.10.0.21', '10.10.0.22' ],
          },
          'subnetMask' => '255.255.255.192',
        },
      },
    },
  ],
}

