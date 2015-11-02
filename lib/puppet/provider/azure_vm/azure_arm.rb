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
      ensure: :present, # TODO: this was unimplemented
      image: build_image_from_reference(machine.properties.storage_profile.image_reference),
      resource_group: machine.id.split('/')[4].downcase,
      location: machine.location,
      size: machine.properties.hardware_profile.vm_size,
      user: machine.properties.os_profile.admin_username,
      os_disk_name: machine.properties.storage_profile.os_disk.name,
      os_disk_caching: machine.properties.storage_profile.os_disk.caching,
      os_disk_create_option: machine.properties.storage_profile.os_disk.create_option,
      object: machine,
    }
  end

  def gen_params
    self.machine_to_hash(Nil)
  end

  def create
    Puppet.info("Creating #{resource[:name]}")
    create_arm_vm(gen_params)
  end

  def destroy
    Puppet.info("Deleting #{resource[:name]}")
    delete_vm(gen_params)
    @property_hash[:ensure] = :absent
  end

  def stop
    Puppet.info("Stopping #{resource[:name]}")
    stop_vm(gen_params)
    @property_hash[:ensure] = :stopped
  end

  def start
    Puppet.info("Starting #{resource[:name]}")
    start_vm(gen_params)
    @property_hash[:ensure] = :running
  end
end
