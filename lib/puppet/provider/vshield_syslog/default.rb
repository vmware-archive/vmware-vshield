# Copyright (C) 2013 VMware, Inc.
provider_path = Pathname.new(__FILE__).parent.parent
require File.join(provider_path, 'vshield')

Puppet::Type.type(:vshield_syslog).provide(:vs_syslog, :parent => Puppet::Provider::Vshield) do
  @doc = 'Manages vShield/NSX appliance syslog configuration.'

  # support vsm ( ver 5.x ) and nsx ( 6.x ) structures
  def version_value
    case network_manager_version 
    when /^6\./
      data = {
        'config_url' => 'api/1.0/appliance-management/system/syslogserver',
        'setting'    => {
          'syslogserver' => {
            'syslogServer' => resource[:syslog_server],
            'port'         => resource[:port],
            'protocol'     => resource[:protocol],
          }
        },
        'server_path' => ['syslogserver','syslogServer'],
        'port_path'   => ['syslogserver','port'],
      } 
    when /^5\./
      data = {
        'config_url'  => 'api/2.0/services/syslog/config',
        'setting'     => {
          'syslogServerConfig' => {
            'serverInfo' => "#{resource[:syslog_server]}:#{resource[:port]}"
          }
        },
        'server_path' => ['syslogServerConfig', 'serverInfo'],
        'port_path'   => ['syslogServerConfig', 'serverInfo'],
      }
    else
      raise "unsupported network manager version: #{network_manager_version}"
    end
    data
  end

  def syslog_settings
    @syslog_settings ||= begin
      get(version_value['config_url'])
    end
  end

  def syslog_server
    server = nested_value(syslog_settings, version_value['server_path'])
    server.split(':').first if server
  end

  # had to split out since calling syslog_server= was not working from flush
  def set_syslog
    Puppet.debug("Setting syslog info")
    config_url = version_value['config_url']
    setting    = version_value['setting']
    put(config_url, setting)
  end

  def syslog_server=(value)
    set_syslog
  end

  def port
    port = nested_value(syslog_settings,version_value['port_path'])
    port.split(':').last if port
  end

  def protocol
      case network_manager_version
      when /^6\./
        nested_value(syslog_settings,['syslogserver','protocol'])
      else
        Puppet.notice("network manager version < 6.0 not supported with parameter 'protocol', setter will be skipped")
        resource[:protocol]
      end
  end

  %w{ port protocol}.each do |prop|
    define_method("#{prop}=") do |value|
      @pending_changes = true
    end
  end

  def flush
    set_syslog if @pending_changes
  end

end
