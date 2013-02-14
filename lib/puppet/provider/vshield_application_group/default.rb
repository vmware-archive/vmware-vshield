# Copyright (C) 2013 VMware, Inc.
provider_path = Pathname.new(__FILE__).parent.parent
require File.join(provider_path, 'vshield')

Puppet::Type.type(:vshield_application_group).provide(:default, :parent => Puppet::Provider::Vshield) do
  @doc = 'Manages vShield Application Group, application groups ( service groups ) can consist of one or more applications and/or other application groups'

  def exists?
    results = ensure_array( nested_value(get("/api/2.0/services/applicationgroup/scope/#{vshield_scope_moref}"), ['list', 'applicationGroup']) )
    # If there's a single application the result is a hash, while multiple results in an array.
    app_group = results.find{|application_group| application_group['name'] == resource[:name]}
    @app_grp = populate_member(app_group)
  end

  def populate_member(app_group)
    if app_group
      app_group['member']                   = ensure_array(app_group['member'])
      app_group['application_member']       = ensure_array(app_group['application_member'])
      app_group['application_group_member'] = ensure_array(app_group['application_group_member'])
    end
    app_group
  end

  def create
    # Create blank application ( service ) group, then poplulate app and app group members
    data = {
      :name     => resource[:name],
    }
    post("api/2.0/services/applicationgroup/#{vshield_scope_moref}", {:applicationGroup => data} )

    # since we just created the blank service group, we need to query to get the id
    results = ensure_array( nested_value(get("/api/2.0/services/applicationgroup/scope/#{vshield_scope_moref}"), ['list', 'applicationGroup']) )

    # If there's a single application the result is a hash, while multiple results in an array.
    app_group = results.find {|application_group| application_group['name'] == resource[:name]}
    process_members( populate_member(app_group) )
  end

  def destroy
    delete("api/2.0/services/applicationgroup/#{@app_grp['objectId']}")
  end

  def application_member
    cur_app_members = []
    applications    = @app_grp['member'].to_a.find_all{ |member| member['objectTypeName'] == 'Application'}
    cur_app_members = applications.collect{ |member| member['name'] }
    cur_app_members.sort
  end

  def application_member=(member)
    @pending_changes = true
  end

  def application_group_member
    cur_app_members = []
    applications    = @app_grp['member'].to_a.find_all{ |member| member['objectTypeName'] == 'ApplicationGroup'}
    cur_app_members = applications.collect{ |member| member['name'] }
    cur_app_members.sort
  end

  def application_group_member=(member)
    @pending_changes = true
  end

  def add_app_members(app_group,app_grp_id)
    # for all application_members add ones not currently members
    app_url = "/api/2.0/services/application/scope/#{vshield_scope_moref}"
    resource[:application_member].each do |app_member|
      results = ensure_array( nested_value(get("#{app_url}"), ['list', 'application']) )
      app     = results.find {|application| application['name'] == app_member}
      add_msg = "Application #{app_member} does not exist, it will not be added to #{resource[:name]}"
      raise Puppet::Error, "#{add_msg}" if app.nil?

      existing_member = ensure_array( app_group['member']).find{ |member| member['name'] == app_member and member['objectTypeName'] == 'Application' }

      if existing_member.nil?
        Puppet.debug("Adding #{app_member} to #{resource[:name]}")
        put("api/2.0/services/applicationgroup/#{app_grp_id}/members/#{app['objectId']}", {} )
      end
    end
  end

  def del_app_members(app_group,app_grp_id)
    # for all current application_members remove ones not in resource[:application_members]
    app_group['member'].each do |app_member|
      app_name = app_member['name']
      app_id   = app_member['objectId']
      unless resource[:application_member].include?(app_name)
        Puppet.debug("Removing #{app_name} from #{resource[:name]}")
        delete("api/2.0/services/applicationgroup/#{app_grp_id}/members/#{app_id}" )
      end
    end
  end

  def add_app_grp_members(app_group,app_grp_id)
    app_grp_url = "/api/2.0/services/applicationgroup/scope/#{vshield_scope_moref}"
    # add all application_groups that are not currently members
    resource[:application_group_member].each do |app_member|
      results = ensure_array( nested_value(get("#{app_grp_url}"), ['list', 'applicationGroup']) )
      app     = results.find {|app_grp| app_grp['name'] == app_member and app_grp['objectTypeName'] == 'ApplicationGroup' }

      # if application does not exist, error out and dont update
      app_msg = "ApplicationGroup #{app_member} does not exist, it will not be added to #{resource[:name]}"
      raise Puppet::Error, "#{app_msg}" if app.nil?
      existing_member = app_group['member'].find{ |member| member['name'] == app_member }

      if existing_member.nil?
        Puppet.debug("Adding #{app_member} to #{resource[:name]}")
        put("api/2.0/services/applicationgroup/#{app_grp_id}/members/#{app['objectId']}", {} )
      end
    end
  end

  def del_app_grp_members(app_group,app_grp_id)
    # for all current application_members remove ones not in resource[:application_members]
    app_group['member'].each do |app_member|
      app_name = app_member['name']
      app_id   = app_member['objectId']
      unless resource[:application_group_member].include?(app_name)
        Puppet.debug("Removing #{app_name} from #{resource[:name]}")
        delete("api/2.0/services/applicationgroup/#{app_grp_id}/members/#{app_id}" )
      end
    end
  end

  def process_members(app_group)
    raise Puppet::Error, "Application Group #{resource[:name]} was not found" unless app_group
    app_grp_id = app_group['objectId']
    raise Puppet::Error, "objectId not found for #{resource[:name]}" if app_grp_id.nil?

    if resource[:application_member]
      add_app_members(app_group,app_grp_id)
      del_app_members(app_group,app_grp_id)
    end
    if resource[:application_group_member]
      add_app_grp_members(app_group,app_grp_id)
      del_app_grp_members(app_group,app_grp_id)
    end
  end

  def flush
    if @pending_changes
      process_members(@app_grp)
    end
  end
end
