# VMware vShield module

This module manages resources in VMware vCloud Network and Security 5.1 (vCNS), i.e. vShield.

## Description

VMware vCloud Network and Security is deployed via a virtual appliance. The
module is able to attach vCNS to a vCenter and manages vCNS 5.1 resources via
[vShield API](https://www.vmware.com/pdf/vshield_51_api.pdf) through REST.

    +------------+         +--------+
    |            | vSphere |  vCSA  | <-
    |   Puppet   | +-----> +--------+  |
    | Management |                     | register
    |    Host    | vShield +--------+  |
    |            | +-----> |  vCNS  | --
    +------------+         +--------+


## Installation

$ puppet module install puppetlabs/vshield

## Usage

Two transport connection is required for managing vShield resources, since vShield is dependent on a vCenter:

    transport { 'vshield':
      username => 'admin',
      password => 'default',
      server   => 'vshield.lab'
    }

    transport { 'vcenter':
      username => 'root',
      password => 'vmware',
      server   => 'vcenter.lab',
      options  => { 'insecure' => true, },
    }

Establishing connection to vCenter is specified by vshield_global_config:

    vshield_global_config { 'vshield.lab'
      vc_info   => {
        ip_address => 'vcenter.lab',
        user_name  => 'root',
        password   => 'vmware',
      },
      time_info => { 'ntp_server' => 'us.pool.ntp.org', }
      dns_info  => { 'primary_dns' => '8.8.8.8' },
      transport => Transport['vshield'],
    }

The vCenter transport server attribute must match
vshield_global_config[vc_info][ip_address] returned by the vShield API.
Connectivity to vCenter is necessary to translate resource (such as a
datacenter, esx host, or folder name) to [vSphere Managed Object Reference
(MoRef)](http://kb.vmware.com/kb/1017126) required by the vShield API.

vshield_edge can be deployed to compute resource in a datacenter:

    vshield_edge { 'vshield.lab:edge_dmz':
      ensure           => present,
      datacenter_name  => 'datacenter_1',
      compute          => 'cluster_dmz_1',
      enable_aesni     => false,
      enable_fips      => false,
      enable_tcp_loose => false,
      vse_log_level    => 'info',
      fqdn             => "edge.dmz.lab",
      transport        => Transport['vshield'],
    }

See tests folder for additional examples.
