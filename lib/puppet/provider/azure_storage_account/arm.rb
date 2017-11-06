require 'puppet_x/puppetlabs/azure/prefetch_error'
require 'puppet_x/puppetlabs/azure/provider_arm'

Puppet::Type.type(:azure_storage_account).provide(:arm, :parent => PuppetX::Puppetlabs::Azure::ProviderArm) do
  confine feature: :azure
  confine feature: :azure_hocon
  confine feature: :azure_retries

  mk_resource_methods

  read_only(:location, :resource_group, :account_kind, :account_type, :sku_name, :sku_tier, :access_tier, :https_traffic_only, :tags)

  def self.instances # rubocop:disable Metrics/AbcSize
    begin
      PuppetX::Puppetlabs::Azure::ProviderArm.new.get_all_sas.collect do |sa|
        hash = {
          name: sa.name,
          ensure: :present,
          location: sa.location,
          tags: sa.tags,
          account_type: sa.sku.name,
          sku_name: sa.sku.name,
          sku_tier: sa.sku.tier,
          account_kind: sa.kind,
          access_tier: sa.access_tier,
          https_traffic_only: sa.enable_https_traffic_only,
          resource_group: sa.id.split('/')[4],
          object: sa,
        }
        Puppet.debug("Ignoring #{name} due to invalid or incomplete response from Azure") unless hash
        new(hash) if hash
      end.compact
    rescue Timeout::Error, StandardError => e
      raise PuppetX::Puppetlabs::Azure::PrefetchError.new(self.resource_type.name.to_s, e)
    end
  end

  # Allow differing case
  def self.prefetch(resources)
    instances.each do |prov|
      if resource = (resources.find { |k,v| k.casecmp(prov.name).zero? } || [])[1] # rubocop:disable Lint/AssignmentInCondition
        resource.provider = prov
      end
    end
  end

  def create # rubocop:disable Metrics/AbcSize
    # storage_account_type and storage_account_kind are enumerated and puppet
    # will automatically convert them to symbols - we need them as strings or we
    # will get an error during serialization
    Puppet.info("Creating storage_account #{resource[:name]} in resource group #{resource[:resource_group]}")
    create_storage_account({
      name: resource[:name],
      resource_group: resource[:resource_group],
      sku_name: resource[:sku_name].to_s || :resource[:account_type].to_s,
      storage_account_kind: resource[:account_kind].to_s,
      access_tier: resource[:access_tier].to_s,
      enable_https_traffic_only: resource[:https_traffic_only],
      location: resource[:location],
      tags: resource[:tags],
    })
    @property_hash[:ensure] = :present
  end

  def destroy
    Puppet.info("Deleting storage_account #{resource[:name]} from resource group #{resource[:resource_group]}")
    delete_storage_account({
      name: resource[:name],
      resource_group: resource[:resource_group],
    })
    @property_hash[:ensure] = :absent
  end
end
