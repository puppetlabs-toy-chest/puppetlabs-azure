require 'puppet_x/puppetlabs/azure/prefetch_error'
require 'puppet_x/puppetlabs/azure/provider'


Puppet::Type.type(:azure_vm).provide(:azure_sdk, :parent => PuppetX::Puppetlabs::Azure::Provider) do
  confine feature: :azure
  confine feature: :azure_hocon
  confine feature: :azure_retries

  mk_resource_methods

  read_only(:location, :deployment, :image, :cloud_service, :size)

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

  def self.ensure_from(status)
    case status
    when 'StoppedDeallocated', 'Stopped'
      :stopped
    else
      :running
    end
  end

  def self.data_disk_size_gb_from(machine)
    if machine.data_disks.empty?
      0
    else
      machine.data_disks.first[:size_in_gb]
    end
  end

  def self.machine_to_hash(machine) # rubocop:disable Metrics/AbcSize
    cloud_service = get_cloud_service(machine.cloud_service_name)
    {
      name: machine.vm_name,
      image: machine.image,
      ensure: ensure_from(machine.status),
      location: cloud_service.location,
      deployment: machine.deployment_name,
      cloud_service: machine.cloud_service_name,
      os_type: machine.os_type,
      ipaddress: machine.ipaddress,
      hostname: machine.hostname,
      media_link: machine.media_link,
      size: machine.role_size,
      cloud_service_object: cloud_service,
      data_disk_size_gb: data_disk_size_gb_from(machine),
      object: machine,
    }
  end

  def exists?
    Puppet.info("Checking if #{name} exists")
    @property_hash[:ensure] and @property_hash[:ensure] != :absent
  end

  def create # rubocop:disable Metrics/AbcSize
    Puppet.info("Creating #{name}")
    params = {
      vm_name: name,
      image: resource[:image],
      location: resource[:location],
      vm_size: resource[:size],
      vm_user: resource[:user],
      password: resource[:password],
      private_key_file: resource[:private_key_file],
      deployment_name: resource[:deployment],
      cloud_service_name: resource[:cloud_service],
      data_disk_size_gb: resource[:data_disk_size_gb],
    }
    create_vm(params)
  end

  def destroy
    Puppet.info("Deleting #{name}")
    delete_vm(machine)
    if resource[:purge_disk_on_delete]
      Puppet.info("Deleting disks for #{name}")
      machine.data_disks.each { |d| delete_disk(d[:name]) }
    end
    @property_hash[:ensure] = :absent
  end

  def stop
    Puppet.info("Stopping #{name}")
    stop_vm(machine)
    @property_hash[:ensure] = :stopped
  end

  def start
    Puppet.info("Starting #{name}")
    start_vm(machine)
    @property_hash[:ensure] = :running
  end

  def running?
    !stopped?
  end

  def stopped?
    ['StoppedDeallocated', 'Stopped'].include? machine.status
  end

  private
  def machine
    vm = if @property_hash[:object]
           @property_hash[:object]
         else
           Puppet.debug("Looking up #{name}")
           find_vm(name)
         end
    raise Puppet::Error, "No virtual machine called #{name}" unless vm
    vm
  end
end
