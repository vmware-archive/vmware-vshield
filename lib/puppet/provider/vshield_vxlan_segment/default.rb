# Copyright (C) 2013 VMware, Inc.
provider_path = Pathname.new(__FILE__).parent.parent
require File.join(provider_path, 'vshield')

Puppet::Type.type(:vshield_vxlan_segment).provide(:default, :parent => Puppet::Provider::Vshield) do
  @doc = 'Manage VXLAN Segment IDs.'

  def vxlan_segment
    @vxlan_segment ||= begin
      segment_config = {}
      segment_url = '/api/2.0/vdn/config/segments'
      results = ensure_array( nested_value(get("#{segment_url}"), ['segmentRanges', 'segmentRange']))
      name = resource['name']
      segment_config = results.find{|segmentRange| segmentRange['name'] == name}
    end
  end

  def exists?
    vxlan_segment
  end

  def replace_properties
    data = {}
    Puppet::Type.type(:vshield_vxlan_segment).parameters.collect.reject{|x| x.to_s =~ /(scope_name|provider)/}.each do |prop|
      if resource[prop]
        camel_prop       = PuppetX::VMware::Util.camelize(prop, :lower)
        data[camel_prop] = resource[prop]
      end
    end
    data
  end

  def create
    post_url = 'api/2.0/vdn/config/segments'
    post("#{post_url}", { 'segmentRange'  => replace_properties } )
  end

  def destroy
    delete("api/2.0/vdn/config/segments/#{vxlan_segment['id']}")
  end

  def flush
    if @pending_changes
      raise Puppet::Error, "segment id pool not found for #{resource[:name]}" unless vxlan_segment
      data    = vxlan_segment.update(replace_properties).reject{|k,v| v.nil?}

      put_url = "api/2.0/config/segments/#{vxlan_segment['id']}"
      Puppet.debug("Updating Segment ID range for: #{resource[:name]}")
      put("#{put_url}", {'segmentRange' => data})
    end
  end

end