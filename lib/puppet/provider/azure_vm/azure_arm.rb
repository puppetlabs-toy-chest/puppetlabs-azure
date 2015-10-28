require 'puppet_x/puppetlabs/azure/prefetch_error'
require 'puppet_x/puppetlabs/azure/provider_arm'

Puppet::Type.type(:azure_vm).provide(:azure_arm, :parent => PuppetX::Puppetlabs::Azure::ProviderArm) do
  confine feature: :azure
  confine feature: :azure_hocon
  confine feature: :azure_retries

  mk_resource_methods

  def self.instances
    begin
      PuppetX::Puppetlabs::Azure::ProviderArm.new.get_all_vms.collect do |machine|
        begin
          hash = machine_to_hash(machine)
          Puppet.debug("Ignoring #{name} due to invalid or incomplete response from Azure") unless hash
          new(hash) if hash
        end
      end.compact
    rescue StandardError => e
      raise PuppetX::Puppetlabs::Azure::PrefetchError.new(self.resource_type.name.to_s, e)
    end
  end

  def self.build_image_from_reference(image_reference)
    "#{image_reference.publisher}:#{image_reference.offer}:#{image_reference.sku}:#{image_reference.version}"
  end

  def self.machine_to_hash(machine) # rubocop:disable Metrics/AbcSize
    {
      name: machine.name,
      image: build_image_from_reference(machine.properties.storage_profile.image_reference),
      ensure: ensure_from(machine.properties.provisioning_state),
      location: machine.location,
      username: machine.properties.os_profile.admin_username,
      hostname: machine.properties.os_profile.computer_name,
      size: machine.properties.hardware_profile.vm_size,
      resource_group: machine.id.split('/')[4].downcase,
    }
  end

  def gen_params # rubocop:disable Metrics/AbcSize
    {
      name: resource[:name],
      image: resource[:image],
      location: resource[:location],
      size: resource[:size],
      user: resource[:user],
      password: resource[:password],
      resource_group: resource[:resource_group],
      storage_account: resource[:storage_account],
      storage_account_type: resource[:storage_account_type],
      os_disk_name: resource[:os_disk_name],
      os_disk_caching: resource[:os_disk_caching],
      os_disk_create_option: resource[:os_disk_create_option],
      os_disk_vhd_container_name: resource[:os_disk_vhd_container_name],
      os_disk_vhd_name: resource[:os_disk_vhd_name],
      dns_domain_name: resource[:dns_domain_name],
      dns_servers: resource[:dns_servers],
      public_ip_allocation_method: resource[:public_ip_allocation_method],
      public_ip_address_name: resource[:public_ip_address_name],
      virtual_network_name: resource[:virtual_network_name],
      virtual_network_address_space: resource[:virtual_network_address_space],
      subnet_name: resource[:subnet_name],
      subnet_address_prefix: resource[:subnet_address_prefix],
      ip_configuration_name: resource[:ip_configuration_name],
      private_ipallocation_method: resource[:private_ipallocation_method],
      network_interface_name: resource[:network_interface_name],
    }
  end

  def create
    params = gen_params
    Puppet.info("Creating #{params[:name]}")
    create_arm_vm(params)
  end

  def destroy
    params = gen_params
    Puppet.info("Deleting #{params[:name]}")
    delete_vm(params)
    @property_hash[:ensure] = :absent
  end

  def stop
    params = gen_params
    Puppet.info("Stopping #{params[:name]}")
    stop_vm(params)
    @property_hash[:ensure] = :stopped
  end

  def start
    params = gen_params
    Puppet.info("Starting #{params[:name]}")
    start_vm(params)
    @property_hash[:ensure] = :running
  end

  def get_all_vms
    get_all_vms
  end
end
