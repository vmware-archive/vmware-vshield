# Copyright (C) 2013 VMware, Inc.
provider_path = Pathname.new(__FILE__).parent.parent
require File.join(provider_path, 'vshield')

Puppet::Type.type(:vshield_firewall).provide(:default, :parent => Puppet::Provider::Vshield) do
  @doc = 'Manages vShield Firewall Rules.'

  def populate_fw_elements
    ipset_url       = "/api/2.0/services/ipset/scope/#{vshield_edge_moref}" 
    @cur_ipsets     = ensure_array( nested_value(get("#{ipset_url}"), ['list', 'ipset' ]) )
    
    app_url         = "/api/2.0/services/application/scope/#{vshield_edge_moref}"
    @cur_apps       = ensure_array( nested_value(get("#{app_url}"), ['list', 'application' ]) )

    grp_url  = "/api/2.0/services/applicationgroup/scope/#{vshield_edge_moref}"
    @cur_app_groups = ensure_array( nested_value(get("#{grp_url}"), ['list', 'applicationGroup' ]) )
  end

  def exists?
    fw_url  = "/api/3.0/edges/#{vshield_edge_moref}/firewall/config"
    results = ensure_array( nested_value(get("#{fw_url}"), [ 'firewall', 'firewallRules', 'firewallRule' ]) )

    # grab ipsets,  apps ( services ), and app groups ( service groups ) for create/flush
    populate_fw_elements

    # A single result is a hash, while multiple results is an array.
    @fw_rule = results.find {|rule| rule['name'] == resource[:name] and rule['ruleType'] == 'user' }

    # populate source,destination and service with [] entries if they are nil
    populate_properties
    @fw_rule
  end

  def populate_properties
    if @fw_rule
      [ 'source', 'destination' ].each do |prop|
        if not @fw_rule[prop] 
          @fw_rule[prop] = {}
          @fw_rule[prop]['groupingObjectId'] = ensure_array(@fw_rule[prop]['groupingObjectId'])
          @fw_rule[prop]['vnicGroupId']      = ensure_array(@fw_rule[prop]['vnicGroupId'])
        end
      end
      if not @fw_rule['application']
        @fw_rule['application'] = {}
        @fw_rule['application']['applicationId'] = ensure_array(@fw_rule['application']['applicationId'])
      end
    end
  end

  def replace_properties
    [ 'source', 'destination' ].each do |src_or_dest|
      next if not resource[src_or_dest.to_sym]
      vnic_group_ids      = []
      grouping_object_ids = []
      resource[src_or_dest.to_sym].each do |name|
        case name
        when /^(external|internal|vse)$/
          vnic_group_ids << name
        when /^vnic[0-9]$/
          vnic_num = name.sub('vnic','')
          vnic_group_ids << "vnic-index-#{vnic_num}"
        else
          ipset = @cur_ipsets.find{|x| x['name'] == name}
          msg   = "ipset: #{name} does not exist for resource: #{resource[:name]},
                   property: #{resource[:"#{src_or_dest}"].inspect}"
          raise Puppet::Error, "#{msg}" if ipset.nil?
          grouping_object_ids << ipset['objectId']
        end
      end
      @fw_rule[src_or_dest]['vnicGroupId']      = vnic_group_ids
      @fw_rule[src_or_dest]['groupingObjectId'] = grouping_object_ids
    end
    @fw_rule['application']['applicationId'] = app_sub_id
    
    # true/false properties, call existing setter methods
    [ 'action', 'enabled', 'logging_enabled' ].each do |prop|
      self.send "#{prop}=".to_sym, resource[prop.to_sym] 
    end
  end

  def create
    @fw_rule = {}
    populate_properties
    replace_properties
    @fw_rule['name']                            = resource[:name]
    data                                      ||= {}
    data[:firewallRule ]                        = @fw_rule.reject{|k,v| v.nil? }
    @just_created                               = true
    post("/api/3.0/edges/#{vshield_edge_moref}/firewall/config/rules", { :firewallRules => data })
  end

  def destroy
    Puppet.notice("delete Not implemented")
  end

  [ 'source', 'destination' ].each do |src_or_dest|
    define_method(src_or_dest.to_sym) do
      names = []
      @fw_rule[src_or_dest]['vnicGroupId']      = ensure_array(@fw_rule[src_or_dest]['vnicGroupId'])
      @fw_rule[src_or_dest]['groupingObjectId'] = ensure_array(@fw_rule[src_or_dest]['groupingObjectId'])

      @fw_rule[src_or_dest]['groupingObjectId'].each do |id|
        ipset = @cur_ipsets.find{|x| x['objectId'] == id}
        names << ipset['name'] if ipset and ipset['name']
      end
      @fw_rule[src_or_dest]['vnicGroupId'].each do |name|
        names << name
      end
      names.sort
    end

    define_method("#{src_or_dest}=".to_sym) do |value|
      @pending_changes = true
    end
  end
  
  [ 'action', 'enabled', 'logging_enabled' ].each do |prop|
    # camel case is used by vshield/nsx
    camel_prop = PuppetX::VMware::Util.camelize(prop, :lower)
    define_method("#{prop}=".to_sym) do |value|
      @fw_rule[camel_prop] = value
      @pending_changes = true
    end
    
    define_method(prop.to_sym) do
      v = @fw_rule[camel_prop]
      v = :false if FalseClass === v
      v = :true  if TrueClass  === v
      v
    end
  end

  def service_application
    service_apps = []
    ensure_array(@fw_rule['application']['applicationId']).each do |id|
      app = @cur_apps.find{|x| x['objectId'] == id and x['objectId'] =~ /^application-/ }
      service_apps << app['name'] if app and app['name']
    end
    service_apps.sort
  end

  def service_group
    service_groups = []
    ensure_array(@fw_rule['application']['applicationId']).each do |id|
      app = @cur_app_groups.find{|x| x['objectId'] == id and x['objectId'] =~ /^applicationgroup-/ }
      service_groups << app['name'] if app and app['name']
    end
    service_groups.sort
  end

  [ 'service_application', 'service_group' ].each do |prop|
    define_method("#{prop}=".to_sym) do |value|
      @pending_changes = true
    end
  end

  def app_sub_id
    ids = []
    resource[:service_application] = [] if resource[:service_application] == [ 'any' ]
    resource[:service_application].each do |name|
      service_app = @cur_apps.find{|x| x['name'] == name}
      app_msg     = "Service: #{name} does not exist for #{resource[:name]}"
      raise Puppet::Error, "#{app_msg}" if service_app.nil?
      ids << service_app['objectId']
    end
    resource[:service_group] = [] if resource[:service_group] == [ 'any' ]
    resource[:service_group].each do |name|
      service_group = @cur_app_groups.find{|x| x['name'] == name}
      group_msg     = "Service Group: #{name} does not exist for #{resource[:name]}"
      raise Puppet::Error, "#{group_msg} " if service_group.nil?
      ids << service_group['objectId']
    end
    ids.sort
  end

  def flush
    unless @just_created
      if @pending_changes
        raise Puppet::Error, "Firewall Rule #{resource[:name]} was not found" unless @fw_rule
        replace_properties
        data                                        = {}
        data[:firewallRule ]                        = @fw_rule.reject{|k,v| v.nil? }
  
        Puppet.debug("Updating fw rule: #{resource[:name]}")      
        put("api/3.0/edges/#{vshield_edge_moref}/firewall/config/rules/#{@fw_rule['id']}", data )
      end
    end
  end
end
