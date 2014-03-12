# Copyright (C) 2013 VMware, Inc.
provider_path = Pathname.new(__FILE__).parent.parent
require File.join(provider_path, 'vshield')

Puppet::Type.type(:vshield_application).provide(:default, :parent => Puppet::Provider::Vshield) do
  @doc = 'Manages vShield application.'

  def exists?
    results = ensure_array( nested_value(get("/api/2.0/services/application/scope/#{vshield_scope_moref}"), ['list', 'application']) )
    # If there's a single application the result is a hash, while multiple results in an array.
    @application = results.find {|application| application['name'] == resource[:name]}
  end

  def create
    data = {
      :revision           => 0,
      :name               => resource[:name],
      :inheritanceAllowed => true,
      :element            => { :value    => resource_value,
                               :applicationProtocol => resource[:application_protocol],
      }
    }
    post("api/2.0/services/application/#{vshield_scope_moref}", {:application => data} )
  end

  def destroy
    delete("api/2.0/services/application/#{@application['objectId']}")
  end

  def value
    @application['element']['value'].split(',')
  end

  def value=(ports)
    @pending_changes = true
  end

  def application_protocol
    @application['element']['applicationProtocol']
  end

  def application_protocol=(proto)
    @pending_changes = true
  end

  def resource_value
    resource[:value].join(',')
  end

  def flush
    if @pending_changes
      # requires us to increment revision number, thing to try in future is omitting revision key
      @application['revision']                       = @application['revision'].to_i + 1
      @application['element']['applicationProtocol'] = resource[:application_protocol]
      @application['element']['value']               = resource_value

      # get rid of nil value hash elements
      data                      = {}
      data[:application]        = @application.reject{|k,v| v.nil? }

      Puppet.debug("Updating to #{resource_value}")
      put("api/2.0/services/application/#{@application['objectId']}", data )

    end
  end

end
