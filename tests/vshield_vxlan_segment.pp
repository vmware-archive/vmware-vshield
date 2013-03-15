# Copyright (C) 2013 VMware, Inc.
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

vc_datacenter { $dc1['name']:
  ensure    => present,
  path      => $dc1['path'],
  transport => Transport['vcenter'],
}

vshield_vxlan_segment { $vxlan_segment1['name']:
  ensure        => present,
  id            => $vxlan_segment1['id'],
  name          => $vxlan_segment1['name'],
  desc          => $vxlan_segment1['desc'],
  begin         => $vxlan_segment1['begin'],
  end           => $vxlan_segment1['end'],
  transport     => Transport['vshield'],
}