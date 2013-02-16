# Copyright (C) 2013 VMware, Inc.
import 'data.pp'

transport { 'vshield':
  username => $vshield['username'],
  password => $vshield['password'],
  server   => $vshield['server'],
}

vshield_global_config { $vshield['server']:
  vc_info   => {
    ip_address => $vcenter['server'],
    user_name  => $vcenter['username'],
    password   => $vcenter['password'],
  },
  time_info => { 'ntp_server' => 'us.pool.ntp.org' },
  dns_info  => { 'primary_dns' => '8.8.8.8' },
  transport => Transport['vshield'],
}
