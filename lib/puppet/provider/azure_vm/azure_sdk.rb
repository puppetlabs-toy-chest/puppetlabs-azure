require 'puppet_x/puppetlabs/azure/prefetch_error'
require 'puppet_x/puppetlabs/azure/provider'


Puppet::Type.type(:azure_vm).provide(:azure_sdk, :parent => PuppetX::Puppetlabs::Azure::Provider) do
  confine feature: :azure
  confine feature: :azure_hocon

  mk_resource_methods

  read_only(:location)

  def self.instances
    begin
      list_vms.collect do |machine|
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

  def self.prefetch(resources)
    instances.each do |prov|
      if resource = resources[prov.name] # rubocop:disable Lint/AssignmentInCondition
        resource.provider = prov
      end
    end
  end

  def self.machine_to_hash(machine)
    cloud_service = get_cloud_service(machine.cloud_service_name)
    {
      name: machine.vm_name,
      image: machine.image,
      ensure: :present,
      location: cloud_service.location,
      cloud_service_object: cloud_service,
      object: machine,
    }
  end

  def exists?
    Puppet.info("Checking if #{name} exists")
    @property_hash[:ensure] and @property_hash[:ensure] != :absent
  end

  def create
    Puppet.info("Creating #{name}")
    params = {
      vm_name: name,
      image: resource[:image],
      location: resource[:location],
      vm_user: resource[:user],
      password: resource[:password],
      private_key_file: resource[:private_key_file],
    }
    create_vm(params)
  end

  def destroy
    Puppet.info("Deleting #{name}")
    delete_vm(@property_hash[:object])
    @property_hash[:ensure] = :absent
  end
end
