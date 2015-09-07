## Require the azure rubygem
#
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'azure'
include Azure

require 'azure/virtual_machine_image_management/virtual_machine_image_management_service'

# Configure these properties
Azure.management_certificate = "/Users/greghardy/azure/cert.pem"
#Azure.subscription_id        = "7fed0c91-ecfd-4fbf-8ca4-0cf53c4e52fa"
Azure.subscription_id        = "c82736ee-c108-452b-8178-f548c95d18fe"

puts "Creating Azure vm_management object"
# Create a virtual machine service object
vm_management = Azure.vm_management
cloud_service = Azure.cloud_service_management
cloud_storage = Azure.storage_management
vm_disk_image_management = Azure.vm_disk_management

puts "Getting a list of the virtual machines for our subscription"
# Get a list of existing virtual machines in your subscription
machine_list = vm_management.list_virtual_machines.select { |machine| machine.name =~ /^cloud/i }

if machine_list then
  machine_list.each do |machine|
    puts "Attempting to delete our virtual machine"
    # API to delete Virtual Machine
    vm_management.delete_virtual_machine(machine.vm_name, machine.cloud_service_name)
  end
end

puts "Deleting cloud services"
services = cloud_service.list_cloud_services.select { |service| service.name =~ /^cloud/i }
if services then
  puts "Services in this account:\n"
  services.each do |service|
    cloud_service.delete_cloud_service(service.name)
  end
end

puts "Listing associated disks"
disks = vm_disk_image_management.list_virtual_machine_disks.select { |disk| disk.name =~ /^cloud/i }
if disks then
  puts "Disks associated with this account:\n"
  disks.each do |disk|
    vm_disk_image_management.delete_virtual_machine_disk(disk.name)
  end
end

puts "Deleting storage accounts"
accounts = cloud_storage.list_storage_accounts.select { |account| account.name =~ /^cloud/i }
if accounts then
  puts "Storage accounts for this subscription:\n"
  accounts.each do |account|
    cloud_storage.delete_storage_account(account.name)
  end
end
