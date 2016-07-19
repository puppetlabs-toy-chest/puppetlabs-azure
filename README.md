[![Build
Status](https://travis-ci.com/puppetlabs/puppetlabs-azure.svg?token=RqtxRv25TsPVz69Qso5L)](https://travis-ci.com/puppetlabs/puppetlabs-azure)

####Table of Contents


1. [Description - What the module does and why it is useful](#module-description)
2. [Setup](#setup)
  * [Requirements](#requirements)
  * [Getting Azure credentials](#getting-azure-credentials)
  * [Installing the Azure module](#installing-the-azure-module)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
  * [Types](#types)
  * [Parameters](#parameters)
5. [Known Issues](#known-issues)
6. [Limitations - OS compatibility, etc.](#limitations)

## Description

Microsoft Azure exposes a powerful API for creating and managing
its Infrastructure as a Service platform. The azure module allows you to
drive that API using Puppet code. This allows you to use Puppet to
create, stop, restart and destroy Virtual Machines and eventually manage
other resources, meaning you can manage even more of your infrastructure
as code.

## Setup

### Requirements

* [Azure gem](https://rubygems.org/gems/azure) 0.7.0 or greater

### Getting Azure credentials

In order to use the Azure module, you'll need an Azure account. If you
already have one you can skip this section, but otherwise you can sign
up for a [Free Trial](http://azure.microsoft.com/en-gb/).

You then need to install the Azure CLI, which is a cross-platform node.js based tool that works on Windows and Linux. This is required to
generate the certificate that we will use later for the Puppet module,
but it's also a useful way of interacting with Azure. Follow this
[installation
guide](https://azure.microsoft.com/en-gb/documentation/articles/xplat-cli-install/)
to get the CLI setup.

Next you need to register the CLI with your Azure account. You can do
this by following this [guide from
Microsoft](https://azure.microsoft.com/en-gb/documentation/articles/xplat-cli-connect/).
The basic steps are:

~~~
azure account download
azure account import <path to your .publishsettings file>
~~~

When you have the account created, you can export the PEM certificate file
using the following command:

~~~
azure account cert export
~~~

And finally, you can get the subscription ID using the `account list` command
like so:

~~~
$ azure account list
info:    Executing command account list
data:    Name                    Id                                     Tenant Id  Current
data:    ----------------------  -------------------------------------  ---------  -------
data:    Pay-As-You-Go           xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxxx  undefined  true
info:    account list command OK
~~~

To use the Resource Manager API instead, you need a service
principal on the Active Directory. A quick way to create one for puppet is [pendrica/azure-credentials](https://github.com/pendrica/azure-credentials). Its [puppet mode](https://github.com/pendrica/azure-credentials#puppet-style-output-note--v-displays-the-file-on-screen-after-creation) can even create the `azure.conf` (see below) for you. Alternatively, the official documentation covers [creating this and retrieving the required credentials](https://azure.microsoft.com/en-us/documentation/articles/resource-group-authenticate-service-principal/).


### Installing the Azure module

1. Install the required gems with this command on Puppet Enterprise 2015.2.0 (puppet-agent 1.2) or later:

   ~~~
   /opt/puppetlabs/puppet/bin/gem install retries --no-ri --no-rdoc
   /opt/puppetlabs/puppet/bin/gem install azure --version='~>0.7.0' --no-ri --no-rdoc
   /opt/puppetlabs/puppet/bin/gem install azure_mgmt_compute --version='~>0.3.0' --no-ri --no-rdoc
   /opt/puppetlabs/puppet/bin/gem install azure_mgmt_storage --version='~>0.3.0' --no-ri --no-rdoc
   /opt/puppetlabs/puppet/bin/gem install azure_mgmt_resources --version='~>0.3.0' --no-ri --no-rdoc
   /opt/puppetlabs/puppet/bin/gem install azure_mgmt_network --version='~>0.3.0' --no-ri --no-rdoc
   /opt/puppetlabs/puppet/bin/gem install hocon --version='~>1.0.0' --no-ri --no-rdoc
   ~~~

   When installing on Windows, launch the `Start Command Prompt with Puppet` and simply type:

   ~~~
   gem install retries --no-ri --no-rdoc
   gem install azure --version="~>0.7.0" --no-ri --no-rdoc
   gem install azure_mgmt_compute --version="~>0.3.0" --no-ri --no-rdoc
   gem install azure_mgmt_storage --version="~>0.3.0" --no-ri --no-rdoc
   gem install azure_mgmt_resources --version="~>0.3.0" --no-ri --no-rdoc
   gem install azure_mgmt_network --version="~>0.3.0" --no-ri --no-rdoc
   gem install hocon --version="~>1.0.0" --no-ri --no-rdoc
   ~~~

   On versions of Puppet Enterprise older than 2015.2.0, use the older path to the `gem` binary:

   ~~~
   /opt/puppet/bin/gem install retries --no-ri --no-rdoc
   /opt/puppet/bin/gem install azure --version='~>0.7.0' --no-ri --no-rdoc
   /opt/puppet/bin/gem install azure_mgmt_compute --version='~>0.3.0' --no-ri --no-rdoc
   /opt/puppet/bin/gem install azure_mgmt_storage --version='~>0.3.0' --no-ri --no-rdoc
   /opt/puppet/bin/gem install azure_mgmt_resources --version='~>0.3.0' --no-ri --no-rdoc
   /opt/puppet/bin/gem install azure_mgmt_network --version='~>0.3.0' --no-ri --no-rdoc
   /opt/puppet/bin/gem install hocon --version='~>1.0.0' --no-ri --no-rdoc
   ~~~

   **Note:** Azure gem installs must be pinned to the correct version detailed in the example above in order for the puppetlabs-azure module to work properly.

   **Note:** Example pins the hocon gem version to prevent possible incompatibilities.

2. Set the following environment variables specific to your Azure
   installation:

   If using the Classic API, you need to provide:

   ~~~
   export AZURE_MANAGEMENT_CERTIFICATE='/path/to/pem/file'
   export AZURE_SUBSCRIPTION_ID='your-subscription-id'
   ~~~

   At a Windows cmd prompt, this should be specified like:

   **Note:** Do not use quotes around any of the values specified below.
   ~~~
   SET AZURE_MANAGEMENT_CERTIFICATE=C:\Path\To\file.pem
   SET AZURE_SUBSCRIPTION_ID=your-subscription-id
   ~~~

   If using the Resource Management API, you need to provide:

   ~~~
   export AZURE_SUBSCRIPTION_ID='your-subscription-id'
   export AZURE_TENANT_ID='your-tenant-id'
   export AZURE_CLIENT_ID='your-client-id'
   export AZURE_CLIENT_SECRET='your-client-secret'
   ~~~

   At a Windows cmd prompt, this should be specified like:

   **Note:** Do not use quotes around any of the values specified below.
   ~~~
   SET AZURE_SUBSCRIPTION_ID=your-subscription-id
   SET AZURE_TENANT_ID=your-tenant-id
   SET AZURE_CLIENT_ID=your-client-id
   SET AZURE_CLIENT_SECRET=your-client-secret
   ~~~

   Note that you can provide all of the above credentials if you are
   working with **both** Resource Manager and Classic virtual machines.

   Alternatively, you can provide the information in a configuration file of [HOCON format](https://github.com/typesafehub/config). Store this as `azure.conf` in the relevant [confdir](https://docs.puppetlabs.com/puppet/latest/reference/dirs_confdir.html). This should be:

   * nix Systems: `/etc/puppetlabs/puppet`
   * Windows: `C:\ProgramData\PuppetLabs\puppet\etc`
   * non-root users: `~/.puppetlabs/etc/puppet`

   The file format is:

   ~~~
   azure: {
     subscription_id: "your-subscription-id"
     management_certificate: "/path/to/pem/file"
   }
   ~~~

   When creating this file on Windows, note that as a JSON-based config file format, paths must be properly escaped like:

   ~~~
   azure: {
     subscription_id: "your-subscription-id"
     management_certificate: "C:\\path\\to\\file.pem"
   }
   ~~~

   > Attention: due to [HC-82](https://tickets.puppetlabs.com/browse/HC-82), please make sure that the file is saved as UTF-8 without a byte order mark (BOM). Otherwise it will be parsed incorrectly.

   Or, with the Resource Management API:

   ~~~
   azure: {
     subscription_id: "your-subscription-id"
     tenant_id: "your-tenant-id"
     client_id: "your-client-id"
     client_secret: "your-client-secret"
   }
   ~~~

   Note that you can use either the environment variables or the config file. If both are present, the environment variables are used. You cannot have some settings in environment variables and others in the config file.

3. Finally, install the module with:

   ~~~
   puppet module install puppetlabs-azure
   ~~~


## Usage

### Create Azure VMs

Azure has two modes for deployment: Classic and Resource Manager. For more information, see [Azure Resource Manager vs. classic deployment: Understand deployment models and the state of your resources](https://azure.microsoft.com/en-us/documentation/articles/resource-manager-deployment-model/). The module supports creating VMs in both deployment modes.

#### Classic
You can create Azure Classic Virtual Machines using the following:

~~~puppet
azure_vm_classic { 'virtual-machine-name':
  ensure           => present,
  image            => 'b39f27a8b8c64d52b05eac6a62ebad85__Ubuntu-14_04_2-LTS-amd64-server-20150706-en-us-30GB',
  location         => 'West US',
  user             => 'username',
  size             => 'Medium',
  private_key_file => '/path/to/private/key',
}
~~~

#### Resource Manager
You can create Azure Resource Manager Virtual Machines using the following:

~~~puppet
azure_vm { 'sample':
  ensure         => present,
  location       => 'eastus',
  image          => 'canonical:ubuntuserver:14.04.2-LTS:latest',
  user           => 'azureuser',
  password       => 'Password_!',
  size           => 'Standard_A0',
  resource_group => 'testresacc01',
}
~~~

You can also add a [virtual machine extension](https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-windows-extensions-features/) to the VM:

~~~puppet
azure_vm { 'sample':
  ensure         => present,
  location       => 'eastus',
  image          => 'canonical:ubuntuserver:14.04.2-LTS:latest',
  user           => 'azureuser',
  password       => 'Password_!',
  size           => 'Standard_A0',
  resource_group => 'testresacc01',
  extensions     => {
    'CustomScriptForLinux' => {
       'auto_upgrade_minor_version' => false,
       'publisher'                  => 'Microsoft.OSTCExtensions',
       'type'                       => 'CustomScriptForLinux',
       'type_handler_version'       => '1.4',
       'settings'                   => {
         'commandToExecute' => 'sh script.sh',
         'fileUris'         => ['https://myAzureStorageAccount.blob.core.windows.net/pathToScript']
       },
     },
  },
}
~~~


This type also has lots of other properties you can manage:

~~~puppet
azure_vm { 'sample':
  location                      => 'eastus',
  image                         => 'canonical:ubuntuserver:14.04.2-LTS:latest',
  user                          => 'azureuser',
  password                      => 'Password',
  size                          => 'Standard_A0',
  resource_group                => 'testresacc01',
  storage_account               => 'teststoracc01',
  storage_account_type          => 'Standard_GRS',
  os_disk_name                  => 'osdisk01',
  os_disk_caching               => 'ReadWrite',
  os_disk_create_option         => 'fromImage',
  os_disk_vhd_container_name    => 'conttest1',
  os_disk_vhd_name              => 'vhdtest1',
  dns_domain_name               => 'mydomain01',
  dns_servers                   => '10.1.1.1.1 10.1.2.4',
  public_ip_allocation_method   => 'Dynamic',
  public_ip_address_name        => 'ip_name_test01pubip',
  virtual_network_name          => 'vnettest01',
  virtual_network_address_space => '10.0.0.0/16',
  subnet_name                   => 'subnet111',
  subnet_address_prefix         => '10.0.2.0/24',
  ip_configuration_name         => 'ip_config_test01',
  private_ip_allocation_method  => 'Dynamic',
  network_interface_name        => 'nicspec01',
  extensions     => {
    'CustomScriptForLinux' => {
       'auto_upgrade_minor_version' => false,
       'publisher'                  => 'Microsoft.OSTCExtensions',
       'type'                       => 'CustomScriptForLinux',
       'type_handler_version'       => '1.4',
       'settings'                   => {
         'commandToExecute' => 'sh script.sh',
         'fileUris'         => ['https://myAzureStorageAccount.blob.core.windows.net/pathToScript']
       },
     },
  },
}
~~~

### List and manage VMs

In addition to describing new machines using the DSL, the module also supports
listing and managing machines via `puppet resource`:

~~~
puppet resource azure_vm_classic
~~~

Note that this will output some information about the machines in your
account:

~~~puppet
azure_vm_classic { 'virtual-machine-name':
  ensure        => 'present',
  cloud_service => 'cloud-service-uptjy',
  deployment    => 'cloud-service-uptjy',
  hostname      => 'garethr',
  image         => 'b39f27a8b8c64d52b05eac6a62ebad85__Ubuntu-14_04_2-LTS-amd64-server-20150706-en-us-30GB',
  ipaddress     => 'xxx.xx.xxx.xx',
  location      => 'West US',
  media_link    => 'http://xxx.blob.core.windows.net/vhds/disk_2015_08_28_07_49_34_868.vhd',
  os_type       => 'Linux',
  size          => 'Medium',
}
~~~

Same command for Azure Resource Manager:

~~~
$ puppet resource azure_vm
~~~

Lists Azure Resource Manager VMs:
~~~puppet
azure_vm { 'sample':
  location         => 'eastus',
  image            => 'canonical:ubuntuserver:14.04.2-LTS:latest',
  user             => 'azureuser',
  password         => 'Password',
  size             => 'Standard_A0',
  resource_group   => 'testresacc01',
}
~~~

## Create Azure Storage Accounts

You can create a [Storage Account](https://azure.microsoft.com/en-us/documentation/articles/storage-create-storage-account/) using the following:

~~~puppet
azure_storage_account { 'myStorageAccount':
  ensure         => present,
  resource_group => 'testresacc01',
  location       => 'eastus',
  account_type   => 'Standard_GRS',
}
~~~
**Note:** Storage Accounts are created with Azure Resource Manager API only.

## Create Azure Resource Groups

You can create a [Resource Group](https://azure.microsoft.com/en-us/documentation/articles/resource-group-overview/#resource-groups) using the following:

~~~puppet
azure_resource_group { 'testresacc01':
  ensure         => present,
  location       => 'eastus',
}
~~~
**Note:** Resource Groups are created with Azure Resource Manager API only.

## Reference

### Types

* `azure_vm_classic`: Manages a virtual machine in Microsoft Azure with Classic Service Management API.
* `azure_vm`: Manages a virtual machine in Microsoft Azure with Azure Resource Manager API.
* `azure_storage_account`: Manages a Storage Account with Azure Resource Manager API.
* `azure_resource_group`: Manages a Resource Group with Azure Resource Manager API.

### Parameters

#### Type: azure_vm_classic

##### `ensure`

Specifies the basic state of the virtual machine. Valid values are 'present',
'running', stopped', and 'absent'. Defaults to 'present'.

Values have the following effects:

* 'present': Ensure that the VM exists in either the running or stopped
  state. If the VM doesn't yet exist, a new one is created.
* 'running': Ensures that the VM is up and running. If the VM
  doesn't yet exist, a new one is created.
* 'stopped': Ensures that the VM is created, but is not running. This
  can be used to shut down running VMs, as well as for creating VMs without
  having them running immediately.
* 'absent': Ensures that the VM doesn't exist on Azure.

##### `name`

*Required* The name of the virtual machine.

##### `image`

Name of the image to use to create the virtual machine. This can be either a VM Image or an OS Image. When specifying a VM Image, `user`, `password`, and `private_key_file` are not used.

##### `location`

*Required* The location where the virtual machine will be created. Details of
available values can be found on the [Azure
regions documentation](http://azure.microsoft.com/en-gb/regions/).
Location is read-only after the VM has been created.

##### `user`

The name of the user to be created on the virtual machine. Required for Linux guests.

##### `password`

The password for the above mentioned user on the virtual machine.

##### `private_key_file`

Path to the private key file for accessing a Linux guest as the above
user.

##### `storage_account`

The name of the storage account to create for the virtual machine.
Note that if the source image is a 'user' image, the storage account
for the user image is used instead of the one provided here. The storage account
must be between 3-24 characters, containing only numeric and/or lower case letters.

##### `cloud_service`

The name of the associated cloud service.

##### `deployment`

The name for the deployment.

##### `size`

The size of the virtual machine instance. See the Azure documentation
for a [full list of
sizes](https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-size-specs/).

##### `affinity_group`

The affinity group to be used for any created cloud service and storage accounts. Use affinity groups to influence colocation of compute and storage for improved performance.

##### `virtual_network`

An existing virtual network to which the virtual machine should be connected.

##### `subnet`

An existing subnet in the specified virtual network to which the virtual machine should be associated.

##### `availability_set`

The availability set for the virtual machine. These are used to ensure
related machines are not all restarted or paused during routine
maintenance.

##### `reserved_ip`

The name of the reserved IP to associate with the virtual machine.

##### `data_disk_size_gb`

The size of the data disk for this virtual machine, specified in gigabytes. Over the life cycle of a disk, this size can only grow. If this value is not set, Puppet does not touch the data disks for this virtual machine.

##### `purge_disk_on_delete`

Whether or not the attached data disk should be deleted when the VM is deleted. Defaults to false.

##### `custom_data`

A block of data to be affiliated with a host upon launch.  On Linux hosts, this can be a script to
be executed on launch by cloud-init. On such Linux hosts, this can either be a single-line command
(for example `touch /tmp/some-file`) which will be run under bash, or a multi-line file (for instance from a
template) which can be any format supported by cloud-init.  This currently doesn't work for Windows hosts.

##### `endpoints`

A list of endpoints to associate with the virtual machine. Supply an array of hashes describing the endpoints. Available keys are:

  * `name`: *Required.* The name of this endpoint.
  * `public_port`: *Required.* The public port to access this endpoint.
  * `local_port`: *Required.* The internal port on which the virtual machine is listening.
  * `protocol`: *Required.* `TCP` or `UDP`.
  * `direct_server_return`: enable direct server return on the endpoint.
  * `load_balancer_name`: If the endpoint should be added to a load balancer set, specify a name here. If the set does not exist yet, it is created automatically.
  * `load_balancer`: A hash of the properties to add this endpoint to a load balancer configuration.
    * `port`: *Required.* The internal port on which the virtual machine is listening.
    * `protocol`: *Required.* The protocol to use for the availability probe.
    * `interval`: The interval for the availability probe in seconds.
    * `path`: a relative path used by the availability probe.

The most often used endpoints are SSH for Linux and WinRM for Windows. Usually they are configured for direct pass-through like this:

~~~
endpoints => [{
    name        => 'ssh',
    local_port  => 22,
    public_port => 22,
    protocol    => 'TCP',
  },]
~~~

or

~~~
endpoints => [{
    name        => 'WinRm-HTTP',
    local_port  => 5985,
    public_port => 5985,
    protocol    => 'TCP',
  },{
    name        => 'PowerShell',
    local_port  => 5986,
    public_port => 5986,
    protocol    => 'TCP',
  },]
~~~

> Note: If you want to manually configure one of the ssh, WinRm-HTTP, or PowerShell endpoints, take care to use those
> endpoint names verbatim. This is required to override Azure's defaults without creating a resource conflict.

##### `os_type`

_Read Only_. The operating system type for the virtual machine.

##### `ipaddress`

_Read Only_. The IP address assigned to the virtual machine.

##### `hostname`

_Read Only_. The hostname of the running virtual machine.

##### `media_link`

_Read Only_. The link to the underlying disk image for the virtual
machine.

#### Type: azure_vm

##### `ensure`
Specifies the basic state of the virtual machine. Valid values are 'present',
'running', stopped', and 'absent'. Defaults to 'present'.

Values have the following effects:

* 'present': Ensure that the VM exists in either the running or stopped
  state. If the VM doesn't yet exist, a new one is created.
* 'running': Ensures that the VM is up and running. If the VM
  doesn't yet exist, a new one is created.
* 'stopped': Ensures that the VM is created, but is not running. This
  can be used to shut down running VMs, as well as for creating VMs without
  having them running immediately.
* 'absent': Ensures that the VM doesn't exist on Azure..

##### `name`
*Required* The name of the virtual machine. The name may have at most 64 characters. Some images may have more restrictive requirements.

##### `image`
*Required* Name of the image to use to create the virtual machine. This must be in the ARM image_refence format
[Azure image reference](https://azure.microsoft.com/en-gb/documentation/articles/virtual-machines-deploy-rmtemplates-azure-cli/)

~~~
canonical:ubuntuserver:14.04.2-LTS:latest
~~~

##### `location`
*Required* The location where the virtual machine will be created. Details of available values can be found on the [Azure regions documentation](http://azure.microsoft.com/en-gb/regions/).
Location is read-only once the VM has been created.

##### `user`
*Required* The name of the user to be created on the virtual machine. Required for Linux guests.

##### `password`
*Required* The password for the above mentioned user on the virtual machine.

##### `size`
*Required* The size of the virtual machine instance. See the Azure documentation
for a [full list of sizes](https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-size-specs/).
ARM requires that the "classic" size be prefixed with Standard. .e.g A0 with ARM is Standard_A0.
D-Series sizes are already prefixed.

##### `resource_group`
*Required* The resource group for the new virtual machine. [Resource Groups](https://azure.microsoft.com/en-gb/documentation/articles/resource-group-overview/)

##### `storage_account`
The storage account name for the subscription id.
Storage account name rules are defined [Storage accounts](https://msdn.microsoft.com/en-us/library/azure/hh264518.aspx)

##### `storage_account_type`
The type of storage account to be associated with the virtual machine.
Valid types are listed [Valid account types](https://msdn.microsoft.com/en-us/library/azure/mt163564.aspx)
Defaults to `Standard_GRS`.

##### `os_disk_name`
The name of the disk that is to be attached to the virtual machine.

##### `os_disk_caching`
The caching type for the attached disk. [Caching](https://azure.microsoft.com/en-gb/documentation/articles/storage-premium-storage-preview-portal/)
Defaults to `ReadWrite`.

##### `os_disk_create_option`
The create options are listed here [Options](https://msdn.microsoft.com/en-us/library/azure/mt163591.aspx)
Defaults to `FromImage`.

##### `os_disk_vhd_container_name`
The vhd container name is used to create the vhd uri of the virtual machine.

This will transpose with storage_account and the os_disk_vhd_name to become the URI of your virtual hard disk image.
~~~
https://#{storage_account}.blob.core.windows.net/#{os_disk_vhd_container_name}/#{os_disk_vhd_name}.vhd
~~~

##### `os_disk_vhd_name`
The name of the vhd that forms the vhd URI for the virtual machine.

##### `dns_domain_name`
The DNS domain name that to be associated with the virtual machine.

##### `dns_servers`
The DNS servers to be setup on the virtual machine.
Defaults to `10.1.1.1 10.1.2.4`

##### `public_ip_allocation_method`
The public ip allocation method [Static, Dynamic]
Defaults to `Dynamic`.

##### `public_ip_address_name`
The key name of the public ip address.

##### `virtual_network_name`
The key name of the virtual network for the virtual machine. [Virtual Network setup](https://msdn.microsoft.com/en-us/library/azure/jj157100.aspx)

##### `virtual_network_address_space`
The ip range for the private virtual network. [Virtual Network setup](https://msdn.microsoft.com/en-us/library/azure/jj157100.aspx)
Default's to `10.0.0.0/16`.

##### `subnet_name`
The private subnet name for the virtual network. [Virtual Network setup](https://msdn.microsoft.com/en-us/library/azure/jj157100.aspx)

##### `subnet_address_prefix`
Details of the prefix are availabe at [Virtual Network setup](https://msdn.microsoft.com/en-us/library/azure/jj157100.aspx)
Default's to `10.0.2.0/24`.

##### `ip_configuration_name`
The key name of the ip configuration for the VM.

##### `private_ip_allocation_method`
The private ip allocation method [Static, Dynamic]
Defaults to `Dynamic`.

##### `network_interface_name`
The Network Interface Controller (nic) name for the virtual machine.

##### `extensions`
The extension to configure on the VM. Azure VM Extensions implement behaviors or features that either help other programs work on Azure VMs. You can optionally configure this parameter to include an extension.
This parameter can be either a single hash (single extension) or multiple hashes (multiple extensions).
Setting the extension parameter to `absent` will delete the extension from the VM.

As an example:  

~~~puppet
extensions     => {
  'CustomScriptForLinux' => {
     'auto_upgrade_minor_version' => false,
     'publisher'                  => 'Microsoft.OSTCExtensions',
     'type'                       => 'CustomScriptForLinux',
     'type_handler_version'       => '1.4',
     'settings'                   => {
       'commandToExecute' => 'sh script.sh',
       'fileUris'         => ['https://myAzureStorageAccount.blob.core.windows.net/pathToScript']
     },
   },
},
~~~

For more information on VM Extensions, see [About virtual machine extensions and features](https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-windows-extensions-features/). Azure VM Extensions support the following parameters:

###### `publisher`
The name of the publisher of the extension.

###### `type`
The type of the extension (e.g. CustomScriptExtension).

###### `type_handler_version`
The version of the extension to use.

###### `settings`
The settings specific to an extension (e.g. CommandsToExecute).

###### `protected_settings`
The settings specific to an extension that are encrypted before passing to the VM.

###### `auto_upgrade_minor_version`
Indicates whether extension should automatically upgrade to latest minor version.

#### Type: azure_storage_account

##### `ensure`

Specifies the basic state of the storage account. Valid values are 'present' and 'absent'. Defaults to 'present'.

##### `name`
*Required* The name of the storage account. Must be globally unique.

##### `location`
*Required* The location where the storage account will be created. Details of
available values can be found on the [Azure
regions documentation](http://azure.microsoft.com/en-gb/regions/).
Location is read-only after the Storage Account has been created.

##### `resource_group`
*Required* The resource group for the new storage account. [Resource Groups](https://azure.microsoft.com/en-gb/documentation/articles/resource-group-overview/)

##### `account_type`
The type of storage account. This indicates the performance level and replication mechanism of the storage account.
Valid types are listed [Valid account types](https://msdn.microsoft.com/en-us/library/azure/mt163564.aspx)
Defaults to `Standard_GRS`.

##### `account_kind`
The kind of storage account. This indicates whether the storage account is general `Storage` or `BlobStorage`.
Defaults to `Storage`.

#### Type: azure_resource_group

##### `ensure`
Specifies the basic state of the resource group. Valid values are 'present' and 'absent'. Defaults to 'present'.

##### `name`
*Required* The name of the resource group. Must be no longer than 80 characters long. It can contain only alphanumeric characters, dash, underscore, opening parenthesis, closing parenthesis, and period. The name cannot end with a period.

##### `location`
*Required* The location where the resource group will be created. Details of
available values can be found on the [Azure
regions documentation](http://azure.microsoft.com/en-gb/regions/).

## Known Issues

In order for the puppetlabs-azure module to work, all [azure gems](#installing-the-azure-module) must be installed successfully. There is a known issue where these gems fail to install if [nokogiri](http://www.nokogiri.org/tutorials/installing_nokogiri.html) failed to install.

## Limitations
Due to a Ruby Azure SDK dependency on the nokogiri gem, running the module on a Windows Agent is only supported with puppet-agent 1.3.0 (a part of Puppet Enterprise 2015.3) and newer.  In that situation, the correct version of nokogiri will be installed when performing the `gem install azure` command mentioned in [Installing the Azure module](#installing-the-azure-module).

## Development

If you run into an issue with this module, or if you would like to request a feature, please [file a ticket](https://tickets.puppetlabs.com/browse/MODULES/).

If you have problems getting this module up and running, please [contact Support](http://puppetlabs.com/services/customer-support).
