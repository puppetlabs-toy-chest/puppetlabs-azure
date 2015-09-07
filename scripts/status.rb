## Require the azure rubygem
#
#
require 'azure'
include Azure
require 'pry'

# Configure these properties
Azure.management_certificate = "/Users/greghardy/azure/cert.pem"
#Azure.subscription_id        = "7fed0c91-ecfd-4fbf-8ca4-0cf53c4e52fa"
Azure.subscription_id        = "c82736ee-c108-452b-8178-f548c95d18fe"


puts "Creating Azure vm_management object"
# Create a virtual machine service object
vm_management = Azure.vm_management
vm_image_management = Azure.vm_image_management
cloud_service = Azure.cloud_service_management
cloud_storage = Azure.storage_management
vm_disk_image_management = Azure.vm_disk_management
=begin
puts "Getting a list of VM images for our subscription"
image_list = vm_image_management.list_virtual_machine_images
puts "images found : #{image_list.size}"
image_list.each do |image|
  puts "#{image.name}"
end
=end

puts "Getting a list of the virtual machines for our subscription"
machine_list = vm_management.list_virtual_machines

if machine_list then
  puts "VMs in this account:\n"
  machine_list.each do |machine|
    puts "\t#{machine.vm_name} #{machine.cloud_service_name} #{machine.status} #{machine.image}"
  end
  puts "\n"
end

puts "Listing cloud services"
services = cloud_service.list_cloud_services
if services then
  puts "Services in this account:\n"
  services.each do |service|
    puts "\t#{service.label} #{service.url} #{service.name} #{service.virtual_machines}"
  end
end

puts "Listing associated disks"
disks = vm_disk_image_management.list_virtual_machine_disks
if disks then
  puts "Disks associated with this account:\n"
  disks.each do |disk|
    puts "\t#{disk.name}"
  end
end

puts "Listing storage accounts"
accounts = cloud_storage.list_storage_accounts
if accounts then
  puts "Storage accounts for this subscription:\n"
  accounts.each do |account|
    puts "\t#{account.name}"
  end
end
