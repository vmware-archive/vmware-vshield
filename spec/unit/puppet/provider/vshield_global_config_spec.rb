require 'spec_helper'

describe 'Puppet::Provider::Vshield_global_config' do
  # Only way to test resource.
  let(:provider) { Puppet::Type.type(:vshield_global_config).provider(:vshield_global_config) }

  before :each do
    provider_class = Puppet::Type.type(:vshield_global_config).provider(:vshield_global_config)
    @resource = Puppet::Type::Vshield_global_config.new(
      :host => '192.168.1.2',
#      :vc_info   => {
#        :ip_address => '192.168.1.1',
#        :user_name  => 'root',
#        :password   => 'vmware',
#      },
      :time_info => { 'ntp_server' => 'us.pool.ntp.org' },
      :dns_info  => { 'primary_dns' => '8.8.8.8' }
    )
    @provider = provider_class.new @resource
  end

  describe 'nested_value' do
    it 'should return a nested value' do
      @provider.nested_value({'a'=>{'b'=>1}}, ['a', 'b']).should == 1
    end
  end

  describe 'ensure_array' do
    it 'should return empty array for nil' do
      @provider.ensure_array(nil).should == []
    end
  end
end
