#### Table of contents

1. [Description - What the module does and why it is useful](#module-description)
2. [Setup](#setup)
   * [Requirements](#requirements)
   * [Get Azure credentials](#get-azure-credentials)
   * [Installing the Azure module](#installing-the-azure-module)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
   * [Types](#types)
   * [Parameters](#parameters)
5. [Known issues](#known-issues)
6. [Limitations - OS compatibility, etc.](#limitations)
7. [Development - reporting issues and getting support](#development)

## Description

Microsoft Azure exposes a powerful API for creating and managing its Infrastructure as a Service platform. The azure module allows you to drive that API using Puppet code. This allows you to use Puppet to create, stop, restart, and destroy Virtual Machines, and eventually to manage other resources, meaning you can manage even more of your infrastructure as code.

## Setup

### Requirements

*   Ruby Gems as follows (see [Installing the Azure module](#installing-the-azure-module), below).
    *   [azure](https://rubygems.org/gems/azure) 0.7.x
    *   [azure_mgmt_storage](https://rubygems.org/gems/azure_mgmt_storage) 0.3.x
    *   [azure_mgmt_compute](https://rubygems.org/gems/azure_mgmt_compute) 0.3.x
    *   [azure_mgmt_resources](https://rubygems.org/gems/azure_mgmt_resources) 0.3.x
    *   [azure_mgmt_network](https://rubygems.org/gems/azure_mgmt_network) 0.14.x
    *   [hocon](https://rubygems.org/gems/hocon) 1.1.x
*   Azure credentials (as detailed below).

#### Get Azure credentials

To use this module, you need an Azure account. If you already have one, you can skip this section.

First, sign up for an [Azure account](https://azure.microsoft.com/en-us/free/).

Install [the Azure CLI 1.0](https://docs.microsoft.com/en-us/azure/cli-install-nodejs), which is a cross-platform node.js-based tool that works on Windows and Linux. This is required to generate a certificate for the Puppet module, but it's also a useful way of interacting with Azure. Currently these instructions have not been updated for the CLI 2.0 tool ('az' commands) but this module uses the API.

[Register the CLI](https://azure.microsoft.com/en-gb/documentation/articles/xplat-cli-connect/) with your Azure account.

On the command line, enter:

``` shell
azure account download
azure account import <path to your .publishsettings file>
```

After you've created the account, export the PEM certificate file using the following command:

``` shell
azure account cert export
```

Next, get a subscription ID using the `azure account list` command:

``` shell
$ azure account list
info:    Executing command account list
data:    Name                    Id                                     Tenant Id  Current
data:    ----------------------  -------------------------------------  ---------  -------
data:    Pay-As-You-Go           xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxxx  undefined  true
info:    account list command OK
```

To use the Resource Manager API instead, you need a service principal on the Active Directory. A quick way to create one for Puppet is [pendrica/azure-credentials](https://github.com/pendrica/azure-credentials). Its [puppet mode](https://github.com/pendrica/azure-credentials#puppet-style-output-note--v-displays-the-file-on-screen-after-creation) can create the `azure.conf` (see below) for you. Alternatively, the official documentation covers [creating this and retrieving the required credentials](https://azure.microsoft.com/en-us/documentation/articles/resource-group-authenticate-service-principal/).

### Installing the Azure module

Install the required gems with this command on `puppet-agent` 1.2 (included in Puppet Enterprise 2015.2.0) or later:

``` shell
/opt/puppetlabs/puppet/bin/gem install retries --no-ri --no-rdoc
/opt/puppetlabs/puppet/bin/gem install azure --version='~>0.7.0' --no-ri --no-rdoc
/opt/puppetlabs/puppet/bin/gem install azure_mgmt_compute --version='~>0.14.0' --no-ri --no-rdoc
/opt/puppetlabs/puppet/bin/gem install azure_mgmt_storage --version='~>0.14.0' --no-ri --no-rdoc
/opt/puppetlabs/puppet/bin/gem install azure_mgmt_resources --version='~>0.14.0' --no-ri --no-rdoc
/opt/puppetlabs/puppet/bin/gem install azure_mgmt_network --version='~>0.14.0' --no-ri --no-rdoc
/opt/puppetlabs/puppet/bin/gem install hocon --version='~>1.1.2' --no-ri --no-rdoc
```

When installing on Windows, launch `Start Command Prompt with Puppet` and enter:

``` shell
gem install retries --no-ri --no-rdoc
gem install azure --version="~>0.7.0" --no-ri --no-rdoc
gem install azure_mgmt_compute --version="~>0.14.0" --no-ri --no-rdoc
gem install azure_mgmt_storage --version="~>0.14.0" --no-ri --no-rdoc
gem install azure_mgmt_resources --version="~>0.14.0" --no-ri --no-rdoc
gem install azure_mgmt_network --version="~>0.14.0" --no-ri --no-rdoc
gem install hocon --version="~>1.1.2" --no-ri --no-rdoc
```

On versions of `puppet agent` older than 1.2 (Puppet Enterprise 2015.2.0), use the older path to the `gem` binary:

``` shell
/opt/puppet/bin/gem install retries --no-ri --no-rdoc
/opt/puppet/bin/gem install azure --version='~>0.7.0' --no-ri --no-rdoc
/opt/puppet/bin/gem install azure_mgmt_compute --version='~>0.14.0' --no-ri --no-rdoc
/opt/puppet/bin/gem install azure_mgmt_storage --version='~>0.14.0' --no-ri --no-rdoc
/opt/puppet/bin/gem install azure_mgmt_resources --version='~>0.14.0' --no-ri --no-rdoc
/opt/puppet/bin/gem install azure_mgmt_network --version='~>0.14.0' --no-ri --no-rdoc
/opt/puppet/bin/gem install hocon --version='~>1.1.2' --no-ri --no-rdoc
```

> **Note:** You must pin Azure gem installs to the correct version detailed in the example above for the azure module to work properly. The example above pins the hocon gem version to prevent possible incompatibilities.

Set the following environment variables specific to your Azure installation.

If using the classic API, provide this information:

``` shell
export AZURE_MANAGEMENT_CERTIFICATE='/path/to/pem/file'
export AZURE_SUBSCRIPTION_ID='your-subscription-id'
```

At a Windows command prompt, specify the information **without quotes around any of the values**:


``` shell
SET AZURE_MANAGEMENT_CERTIFICATE=C:\Path\To\file.pem
SET AZURE_SUBSCRIPTION_ID=your-subscription-id
```

If using the Resource Management API, provide this information:

``` shell
export AZURE_SUBSCRIPTION_ID='your-subscription-id'
export AZURE_TENANT_ID='your-tenant-id'
export AZURE_CLIENT_ID='your-client-id'
export AZURE_CLIENT_SECRET='your-client-secret'
```

At a Windows command prompt, specify the information **without quotes around any of the values**:

``` shell
SET AZURE_SUBSCRIPTION_ID=your-subscription-id
SET AZURE_TENANT_ID=your-tenant-id
SET AZURE_CLIENT_ID=your-client-id
SET AZURE_CLIENT_SECRET=your-client-secret
```

If you are working with **both** Resource Manager and classic virtual machines, provide all of the above credentials.

Alternatively, you can provide the information in a configuration file of [HOCON format](https://github.com/typesafehub/config). Store this as `azure.conf` in the relevant [confdir](https://docs.puppetlabs.com/puppet/latest/reference/dirs_confdir.html):

* \*nix Systems: `/etc/puppetlabs/puppet`
* Windows: `C:\ProgramData\PuppetLabs\puppet\etc`
* Non-root users: `~/.puppetlabs/etc/puppet`

The file format is:

``` shell
azure: {
  subscription_id: "your-subscription-id"
  management_certificate: "/path/to/pem/file"
}
```

When creating this file on Windows, note that as a JSON-based config file format, paths must be properly escaped:

``` shell
azure: {
  subscription_id: "your-subscription-id"
  management_certificate: "C:\\path\\to\\file.pem"
}
```

> **Note**: Make sure to have at least hocon 1.1.2 installed on windows. With older versions, you have to make sure to make sure that the `azure.conf` is encoded as UTF-8 without a byte order mark (BOM). See [HC-82](https://tickets.puppetlabs.com/browse/HC-82), and [HC-83](https://tickets.puppetlabs.com/browse/HC-83) for technical details. Starting with hocon 1.1.2, UTF-8 with or without BOM works.

Or, with the Resource Management API:

``` shell
azure: {
  subscription_id: "your-subscription-id"
  tenant_id: "your-tenant-id"
  client_id: "your-client-id"
  client_secret: "your-client-secret"
}
```

You can use either the environment variables **or** the config file. If both are present, the environment variables are used. You cannot have some settings in environment variables and others in the config file.

Next, Install the module with:

``` shell
puppet module install puppetlabs-azure
```

## Usage

### Create Azure VMs

Azure has two modes for deployment: Classic and Resource Manager. For more information, see [Azure Resource Manager vs. classic deployment: Understand deployment models and the state of your resources](https://azure.microsoft.com/en-us/documentation/articles/resource-manager-deployment-model/). The module supports creating VMs in both deployment modes.

#### Classic

You can create Azure classic virtual machines using the following:

```puppet
azure_vm_classic { 'virtual-machine-name':
  ensure           => present,
  image            => 'b39f27a8b8c64d52b05eac6a62ebad85__Ubuntu-14_04_2-LTS-amd64-server-20150706-en-us-30GB',
  location         => 'West US',
  user             => 'username',
  size             => 'Medium',
  private_key_file => '/path/to/private/key',
}
```

#### Resource Manager

You can create Azure Resource Manager virtual machines using the following:

```puppet
azure_vm { 'sample':
  ensure         => present,
  location       => 'eastus',
  image          => 'canonical:ubuntuserver:14.04.2-LTS:latest',
  user           => 'azureuser',
  password       => 'Password_!',
  size           => 'Standard_A0',
  resource_group => 'testresacc01',
}
```

You can also add a [virtual machine extension](https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-windows-extensions-features/) to the VM and deploy from a [Marketplace product](https://azure.microsoft.com/en-us/blog/working-with-marketplace-images-on-azure-resource-manager/) instead of an image:

```puppet
azure_vm { 'sample':
  ensure         => present,
  location       => 'eastus',
  user           => 'azureuser',
  password       => 'Password_!',
  size           => 'Standard_A0',
  resource_group => 'testresacc01',
  plan           => {
    'name'      => '2016-1',
    'product'   => 'puppet-enterprise',
    'publisher' => 'puppet',
  },
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
```

This type also has many other properties you can manage:

```puppet
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
  network_security_group_name   => 'My-Network-Security-Group',
  tags                          => { 'department' => 'devops', 'foo' => 'bar' },
  extensions                    => {
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
```

#### Premium Storage

Azure supports _premium_ SSD backed VMs for enhanced performance of production class environments.  SSD storage can be selected at the time of VM creation like this (`Premium_LRS` is the Azure API's internal representation):

```puppet
azure_vm { 'ssd-example':
  ensure               => present,
  location             => 'centralus',
  image                => 'Canonical:UbuntuServer:16.10:latest',
  user                 => 'azureuser',
  password             => 'Password_!',
  size                 => 'Standard_DS1_v2',
  resource_group       => 'puppetvms',
  storage_account_type => 'Premium_LRS',
}

```

To successfully enable `Premium_LRS`, you **must** select a premium-capable VM size such as `Standard_DS1_v2`.  Regular HDD backed VMs can be created by using `Standard_LRS`.

#### Boot/guest diagnostics

The Azure portal provides switches to enable _boot_diagnostics_ and _guest diagnostics_.  Both switches require access to a storage account to dump the diagnostic data.

The switch behaves differently depending what is activated:

* Boot diagnostics - Configures the VM `diagnosticsProfile` setting to write out boot diagnostics .  If required, manually enable using the portal.  Since boot diagnostics only apply at boot time, their most useful for interactive debugging when a VM is having a problems booting.  If required, boot diagnostics can be enabled through the Azure portal.
* Guest diagnostics - Configures an extension to capture live diagnostic output.  This needs to be _different_ depending on the selected guest OS and is enabled by supplying the appropriate data to the `extensions` parameter.

#### Managed Disks

Azure's _managed disks_ feature removes the requirement to associate a storage account with each Azure VM. To use managed disks with `azure_vm`, set the `managed_disks` parameter to true:

```puppet
azure_vm { 'managed-disks-example':
  ensure        => present,
  location      => 'centralus',
  image         => 'Canonical:UbuntuServer:16.10:latest',
  user          => 'azureuser',
  password      => 'Password_!',
  managed_disks => true,
}
```

When using _managed disks_ it's not possible to set _vhd_ options, the _managed disks_ feature takes care of these for you.

#### Connecting to networks

You can create Azure Resource Manager virtual networks using the following:

```puppet
azure_virtual_network { 'vnettest01':
  ensure           => present,
  location         => 'eastus',
  address_prefixes => ['10.0.0.0/16'], # Array of IP address prefixes for the VNet
  dns_servers      => [],              # Array of DNS server IP addresses
}
```

Specify the network objects to avoid creating your VM in a miniture DMZ where it can't reach other networks. To attach a VM to a virtual network, specify the `virtual_network_name`, `subnet_name` and `network_security_group_name` parameters. These all allow slashes to lookup the requested object in other resource groups.  Note that `subnet_name` must also specify the virtual network if using this feature:

```puppet
azure_vm { 'web01':
  ensure                      => present,
  location                    => 'centralus',
  image                       => 'canonical:ubuntuserver:14.04.2-LTS:latest',
  user                        => 'azureuser',
  password                    => 'Password_!',
  size                        => 'Standard_A0',
  resource_group              => 'webservers-rg',
  virtual_network_name        => 'hq-rg/delivery-vn',
  subnet_name 	              => "hq-rg/delivery-vn/web-sn",
  network_security_group_name => "hq-rg/delivery-nsg",
}
```

If virtual network parameters specified in the `azure_vm` do not exist, they will be created in the same resource group as the VM.  This works for basic environments where everything you want to talk to on non-public addresses is within the same resource group. You can avoid this automatic creation by not specifying `virtual_network_address_space`

```puppet
azure_vm { 'web01':
  ensure                        => present,
  location                      => 'centralus',
  resource_group                => 'webservers-rg',
  virtual_network_name          => 'vnettest01',
  virtual_network_address_space => '10.0.0.0/16',
  ...
}
```

### List and manage VMs

This module supports listing and managing machines via `puppet resource`.

For example:

``` shell
puppet resource azure_vm_classic
```

This outputs some information about the machines in your account:

```puppet
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
```

Use the same command for Azure Resource Manager:

``` shell
puppet resource azure_vm
```

This lists Azure Resource Manager VMs:

```puppet
azure_vm { 'sample':
  location       => 'eastus',
  image          => 'canonical:ubuntuserver:14.04.2-LTS:latest',
  user           => 'azureuser',
  password       => 'Password',
  size           => 'Standard_A0',
  resource_group => 'testresacc01',
}
```

### Create Azure storage accounts

You can create a [storage account](https://azure.microsoft.com/en-us/documentation/articles/storage-create-storage-account/) using the following:

```puppet
azure_storage_account { 'myStorageAccount':
  ensure         => present,
  resource_group => 'testresacc01',
  location       => 'eastus',
  account_type   => 'Standard_GRS',
}
```

> **Note:** Storage accounts are created with the Azure Resource Manager API only.

### Create Azure resource groups

You can create a [resource group](https://azure.microsoft.com/en-us/documentation/articles/resource-group-overview/#resource-groups) using the following:

```puppet
azure_resource_group { 'testresacc01':
  ensure   => present,
  location => 'eastus',
}
```

> **Note:** Resource groups are created with Azure Resource Manager API only.

### Create Azure template deployment

You can create a [resource template deployment](https://azure.microsoft.com/en-us/documentation/articles/solution-dev-test-environments/) using the following:

```puppet
azure_resource_template { 'My-Network-Security-Group':
  ensure         => 'present',
  resource_group => 'security-testing',
  source         => 'https://gallery.azure.com/artifact/20151001/Microsoft.NetworkSecurityGroup.1.0.0/DeploymentTemplates/NetworkSecurityGroup.json',
  params         => {
    'location'                 => 'eastasia',
    'networkSecurityGroupName' => 'testing',
  },
}
```

> **Note:** Resource templates are deployed with Azure Resource Manager API only.

## Reference

### Types

* [`azure_vm_classic`](#type-azure_vm_classic): Manages a virtual machine in Microsoft Azure with Classic Service Management API.
* `azure_vm`: Manages a virtual machine in Microsoft Azure with Azure Resource Manager API.
* `azure_storage_account`: Manages a Storage Account with Azure Resource Manager API.
* `azure_resource_group`: Manages a Resource Group with Azure Resource Manager API.
* `azure_resource_template`: Manages a Resource Template with Azure Resource Manager API.

### Parameters

Parameters are optional unless specified **Required**.

#### Type: azure_vm_classic

##### `ensure`

Specifies the basic state of the virtual machine.

Values: 'present', 'running', stopped', 'absent'.

Values have the following effects:

* 'present': Ensure that the VM exists in either the running or stopped state. If the VM doesn't yet exist, a new one is created.
* 'running': Ensures that the VM is up and running. If the VM doesn't yet exist, a new one is created.
* 'stopped': Ensures that the VM is created, but is not running. This can be used to shut down running VMs, as well as for creating VMs without having them running immediately.
* 'absent': Ensures that the VM doesn't exist on Azure.

Default: 'present'.

##### `name`

**Required**.

The name of the virtual machine.

##### `image`

Name of the image to use to create the virtual machine. This can be either a VM Image or an OS Image. When specifying a VM Image, `user`, `password`, and `private_key_file` are not used.

##### `location`

**Required**.

The location where the virtual machine is created. Details of available values can be found on the [Azure regions documentation](http://azure.microsoft.com/en-gb/regions/). Location is read-only after the VM has been created.

##### `user`

**Required** for Linux guests.

The name of the user to be created on the virtual machine.

##### `password`

The password for the above mentioned user on the virtual machine.

##### `private_key_file`

Path to the private key file for accessing a Linux guest as the above user.

##### `storage_account`

The name of the storage account to create for the virtual machine. If the source image is a 'user' image, the storage account for the user image is used instead of the one provided here.

Values: A string between 3-24 characters, containing only numeric and/or lower case letters.

##### `cloud_service`

The name of the associated cloud service.

##### `deployment`

The name for the deployment.

##### `size`

The size of the virtual machine instance.

Values: See the Azure documentation for a [full list of sizes](https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-size-specs/).

##### `affinity_group`

The affinity group to be used for any created cloud service and storage accounts. Use affinity groups to influence colocation of compute and storage for improved performance.

##### `virtual_network`

An existing virtual network to which the virtual machine should be connected.

##### `subnet`

An existing subnet in the specified virtual network to which the virtual machine should be associated.

##### `availability_set`

The availability set for the virtual machine. These are used to ensure related machines are not all restarted or paused during routine maintenance.

##### `reserved_ip`

The name of the reserved IP to associate with the virtual machine.

##### `data_disk_size_gb`

The size of the data disk for this virtual machine, specified in gigabytes. Over the life cycle of a disk, this size can only grow. If this value is not set, Puppet does not touch the data disks for this virtual machine.

##### `purge_disk_on_delete`

Whether or not the attached data disk should be deleted when the VM is deleted.

Values: Boolean.

Default: `false`.

##### `custom_data`

A block of data to be affiliated with a host upon launch. On Linux hosts, this can be a script to be executed on launch by cloud-init. On such Linux hosts, this can either be a single-line command (for example `touch /tmp/some-file`) which runs under bash, or a multi-line file (for instance from a template) which can be any format supported by cloud-init.

Windows images (and Linux images without cloud-init) need to provide their own mechanism to execute or act on the provided data.

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

``` shell
endpoints => [{
    name        => 'ssh',
    local_port  => 22,
    public_port => 22,
    protocol    => 'TCP',
  },]
```

or

``` shell
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
```

> **Note:** To manually configure one of the ssh, WinRm-HTTP, or PowerShell endpoints, use those endpoint names verbatim. This is required to override Azure's defaults without creating a resource conflict.

##### `os_type`

_Read Only_.

The operating system type for the virtual machine.

##### `ipaddress`

_Read Only_.

The IP address assigned to the virtual machine.

##### `hostname`

_Read Only_.

The hostname of the running virtual machine.

##### `media_link`

_Read Only_.

The link to the underlying disk image for the virtual machine.

#### Type: azure_vnet

##### `ensure`

Specifies the basic state of the virtual machine.

Values: 'present', 'running', stopped', 'absent'.

Values have the following effects:

* 'present': Ensure that the virtual network exists in Azure. If the virtual network doesn't yet exist, a new one is created.
* 'absent': Ensures that the virtual network doesn't exist on Azure

Default: 'present'.

##### `name`

**Required**.

The name of the virtual network. The name can have 64 characters at most.

##### `location`

**Required**.

Location to create the virtual network. Location is read-only after the vnet has been created.

Values: See [Azure regions documentation](http://azure.microsoft.com/en-gb/regions/).

##### `resource_group`

**Required**.

The resource group for the new virtual network.

Values: See [Resource Groups](https://azure.microsoft.com/en-gb/documentation/articles/resource-group-overview/).

##### `dns_servers`

An array of DNS servers to be given to vms in the virtual network

Default: [] # None

##### `address_prefixes`

Details of the prefix are available at [Virtual Network setup](https://msdn.microsoft.com/en-us/library/azure/jj157100.aspx).

Default: ['10.0.0.0/16']

#### Type: azure_network_security_group

##### `ensure`

Specifies the basic state of the virtual machine.

Values: 'present', 'absent'.

Values have the following effects:

* 'present': Ensure that the network security group exists in Azure. If it doesn't yet exist, a new one is created.
* 'absent': Ensures that the network security group doesn't exist on Azure

Default: 'present'.

##### `name`

**Required**.

The name of the network security group. The name can have 64 characters at most.

##### `location`

**Required**.

Location to create the virtual network. Location is read-only after the vnet has been created.

Values: See [Azure regions documentation](http://azure.microsoft.com/en-gb/regions/).

##### `resource_group`

**Required**.

The resource group for the new virtual network.

Values: See [Resource Groups](https://azure.microsoft.com/en-gb/documentation/articles/resource-group-overview/).

##### `tags`

A hash of tags to label with.

Example:

```puppet
tags => {'department' => 'devops', 'foo' => 'bar'}
```

#### Type: azure_vm

##### `ensure`

Specifies the basic state of the virtual machine.

Values: 'present', 'running', stopped', 'absent'.

Values have the following effects:

* 'present': Ensure that the VM exists in either the running or stopped state. If the VM doesn't yet exist, a new one is created.
* 'running': Ensures that the VM is up and running. If the VM doesn't yet exist, a new one is created.
* 'stopped': Ensures that the VM is created, but is not running. This can be used to shut down running VMs, as well as for creating VMs without having them running immediately.
* 'absent': Ensures that the VM doesn't exist on Azure.

Default: 'present'.

##### `name`

**Required**.

The name of the virtual machine. The name can have 64 characters at most. Some images may have more restrictive requirements.

##### `image`

Name of the image to use to create the virtual machine. **Required** if no Marketplace `plan` is provided.

Values: Must be in the ARM image_reference format. See the [Azure image reference](https://azure.microsoft.com/en-gb/documentation/articles/virtual-machines-deploy-rmtemplates-azure-cli/).

``` shell
canonical:ubuntuserver:14.04.2-LTS:latest
```

##### `location`

**Required**.

Location to create the virtual machine. Location is read-only after the VM has been created.

Values: See [Azure regions documentation](http://azure.microsoft.com/en-gb/regions/).

##### `user`

**Required** for Linux guests.

The name of the user to be created on the virtual machine.

##### `password`

**Required**.

The password for the user on the virtual machine.

##### `size`

**Required**.

The size of the virtual machine instance. ARM requires that the "classic" size be prefixed with Standard; for example, A0 with ARM is Standard_A0. D-Series sizes are already prefixed.

Values: See the Azure documentation for a [full list of sizes](https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-size-specs/).

##### `resource_group`

**Required**.

The resource group for the new virtual machine.

Values: See [Resource Groups](https://azure.microsoft.com/en-gb/documentation/articles/resource-group-overview/).

##### `storage_account`

The storage account name for the subscription id.

Storage account name rules are defined in [Storage accounts](https://msdn.microsoft.com/en-us/library/azure/hh264518.aspx).

##### `storage_account_type`

The type of storage account to be associated with the virtual machine.

See [Valid account types](https://msdn.microsoft.com/en-us/library/azure/mt163564.aspx).
Default: `Standard_GRS`.

##### `os_disk_name`

The name of the disk that is to be attached to the virtual machine.

##### `os_disk_caching`

The caching type for the attached disk.

See [Caching](https://azure.microsoft.com/en-gb/documentation/articles/storage-premium-storage-preview-portal/).

Default: `ReadWrite`.

##### `os_disk_create_option`

Create options are listed at [Options](https://msdn.microsoft.com/en-us/library/azure/mt163591.aspx).

Default: `FromImage`.

##### `os_disk_vhd_container_name`

The vhd container name is used to create the vhd uri of the virtual machine.

This transposes with storage_account and the os_disk_vhd_name to become the URI of your virtual hard disk image.

``` shell
https://#{storage_account}.blob.core.windows.net/#{os_disk_vhd_container_name}/#{os_disk_vhd_name}.vhd
```

##### `os_disk_vhd_name`

The name of the vhd that forms the vhd URI for the virtual machine.

##### `dns_domain_name`

The DNS domain name that to be associated with the virtual machine.

##### `dns_servers`

The DNS servers to be setup on the virtual machine.

Default: '10.1.1.1 10.1.2.4'

##### `public_ip_allocation_method`

The public IP allocation method.

Values: 'Static', 'Dynamic', 'None'.

Default: 'Dynamic'.

##### `public_ip_address_name`

The key name of the public IP address.

##### `virtual_network_name`

The key name of the virtual network for the virtual machine.

See [Virtual Network setup](https://msdn.microsoft.com/en-us/library/azure/jj157100.aspx)

##### `virtual_network_address_space`

The ip range for the private virtual network.

May be a string or array of strings. See [Virtual Network setup](https://msdn.microsoft.com/en-us/library/azure/jj157100.aspx).

Default: '10.0.0.0/16'.

##### `subnet_name`

The private subnet name for the virtual network. See [Virtual Network setup](https://msdn.microsoft.com/en-us/library/azure/jj157100.aspx).

##### `subnet_address_prefix`

Details of the prefix are available at [Virtual Network setup](https://msdn.microsoft.com/en-us/library/azure/jj157100.aspx).

Default: '10.0.2.0/24'

##### `ip_configuration_name`

The key name of the IP configuration for the VM.

##### `private_ip_allocation_method`

The private ip allocation method.

Values: 'Static', 'Dynamic'.

Default: 'Dynamic'

##### `network_interface_name`

The Network Interface Controller (nic) name for the virtual machine.

##### `custom_data`

A block of data to be affiliated with a host upon launch. On Linux hosts, this can be a script to be executed on launch by cloud-init. On such Linux hosts, this can either be a single-line command (for example `touch /tmp/some-file`), which is run under bash, or a multi-line file (for instance from a template), which can be any format supported by cloud-init.

Windows images (and Linux images without cloud-init) need to provide their own mechanism to execute or act on the provided data.

##### `data_disks`

Manages one or more data disks attached to an Azure VM. This parameter expects a hash where the key is the name of the data disk and the value is a hash of data disk properties.

Azure VM data_disks support the following parameters:

###### `caching`

Specifies the caching behavior of data disk.

Values:

* 'None'
* 'ReadOnly'
* 'ReadWrite'

The default value is 'None'.

###### `create_option`

Specifies the create option for the disk image.

Values: 'FromImage', 'Empty', 'Attach'.

###### `data_size_gb`

Specifies the size, in GB, of an empty disk to be attached to the Virtual Machine.

###### `lun`

Specifies the Logical Unit Number (LUN) for the disk. The LUN specifies the slot in which the data drive appears when mounted for usage by the Virtual Machine.

Values: Valid LUN values, 0 through 31.

###### `vhd`

Specifies the location of the blob in storage where the vhd file for the disk is located. The storage account where the vhd is located must be associated with the specified subscription.

Example:

``` shell
http://example.blob.core.windows.net/disks/mydisk.vhd
```

##### `plan`

Deploys the VM from an Azure Software Marketplace product (called a "plan"). Required if no `image` is specified.

Value must be a hash with three required keys: `name`, `product`, and `publisher`. `promotion_code` is an optional fourth key.

Example:

```puppet
plan => {
  'name'      => '2016-1',
  'product'   => 'puppet-enterprise',
  'publisher' => 'puppet',
},
```

##### `tags`

A hash of tags to label with.

Example:

```puppet
tags => {'department' => 'devops', 'foo' => 'bar'}
```

##### `extensions`

The extension to configure on the VM. Azure VM Extensions implement behaviors or features that either help other programs work on Azure VMs. You can optionally configure this parameter to include an extension.

This parameter can be either a single hash (single extension) or multiple hashes (multiple extensions). Setting the extension parameter to 'absent' deletes the extension from the VM.

Example:

```puppet
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
```

To install the Puppet agent as an extension on a Windows VM:

```puppet
extensions     => {
  'PuppetExtension' => {
     'auto_upgrade_minor_version' => true,
     'publisher'                  => 'Puppet',
     'type'                       => 'PuppetAgent',
     'type_handler_version'       => '1.5',
     'protected_settings'                   => {
       'PUPPET_MASTER_SERVER': 'mypuppetmaster.com'
     },
   },
},
```

For more information on VM Extensions, see [About virtual machine extensions and features](https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-windows-extensions-features/). For information on how to configure a particular extension, see [Azure Windows VM Extension Configuration Samples](https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-windows-extensions-configuration-samples/).

Azure VM Extensions support the following parameters:

###### `publisher`

The name of the publisher of the extension.

###### `type`

The type of the extension (for example, CustomScriptExtension).

###### `type_handler_version`

The version of the extension to use.

###### `settings`

The settings specific to an extension (for example, CommandsToExecute).

###### `protected_settings`

The settings specific to an extension that are encrypted before passing to the VM.

###### `auto_upgrade_minor_version`

Indicates whether extension should automatically upgrade to latest minor version.

#### Type: azure_storage_account

##### `ensure`

Specifies the basic state of the storage account.

Values: 'present', 'absent'.

Default: 'present'.

##### `name`

**Required**.

The name of the storage account. Must be globally unique.

##### `location`

**Required**

The location where the storage account is created. Location is read-only after the Storage Account has been created.

Values: See the [Azure regions documentation](http://azure.microsoft.com/en-gb/regions/).

##### `resource_group`

**Required**.

The resource group for the new storage account.

Values: See [Resource Groups](https://azure.microsoft.com/en-gb/documentation/articles/resource-group-overview/).

##### `account_type`

The type of storage account. This indicates the performance level and replication mechanism of the storage account.

Values: See [Valid account types](https://msdn.microsoft.com/en-us/library/azure/mt163564.aspx).

Defaults to 'Standard_GRS'.

##### `account_kind`

The kind of storage account.

Values: 'Storage' or 'BlobStorage'.

Default: 'Storage'.

##### `tags`

A hash of tags to label with.

Example:

```puppet
tags => {'department' => 'devops', 'foo' => 'bar'}
```

#### Type: azure_resource_group

##### `ensure`

Specifies the basic state of the resource group.

Values: 'present', 'absent'.

Default: 'present'.

##### `name`

**Required**.

The name of the resource group.

Values: A string no longer than 80 characters long, containing only alphanumeric characters, dash, underscore, opening parenthesis, closing parenthesis, and period. The name cannot end with a period.

##### `location`

**Required**.

The location where the resource group is created.

Values: See [Azure regions documentation](http://azure.microsoft.com/en-gb/regions/).

##### `tags`
A hash of tags to label with.

Example:

```puppet
tags => {'department' => 'devops', 'foo' => 'bar'}
```

#### Type: azure_resource_template

#### `ensure`

Specifies the basic state of the resource group.

Values: 'present' and 'absent'. Defaults to 'present'.

##### `name`

**Required**.

The name of the template deployment.

Values: A string no longer than 80 characters long, containing only alphanumeric characters, dash, underscore, opening parenthesis, closing parenthesis, and period. The name cannot end with a period.

##### `resource_group`

**Required**.

The resource group for the new template deployment.

Values: See [Resource Groups](https://azure.microsoft.com/en-gb/documentation/articles/resource-group-overview/)..

##### `source`

The URI of a template. May be http:// or https://.

Must not be specified when `content` is specified.

##### `content`

The text of an Azure Resource Template.

Must not be specified when `source` is specified.

##### `params`

The params that are required by the Azure Resource Template. Follows the form of `{ 'key_one' => 'value_one', 'key_two' => 'value_two'}`.

This format is specific to Puppet. Must not be specified when `params_source` is specified.

##### `params_source`

The URI of a file containing the params in Azure Resource Model standard format.

The format of this file differs from the format accepted by the `params` attribute. Must not be specified when `params` is specified.

## Known issues

For the azure module to work, all [azure gems](#installing-the-azure-module) must be installed successfully. There is a known issue where these gems fail to install if [nokogiri](http://www.nokogiri.org/tutorials/installing_nokogiri.html) failed to install.

## Limitations

Because of a Ruby Azure SDK dependency on the nokogiri gem, running the module on a Windows Agent is supported only with puppet-agent 1.3.0 (a part of Puppet Enterprise 2015.3) and newer. In these versions, the correct version of nokogiri is installed when you run the `gem install azure` command mentioned in [Installing the Azure module](#installing-the-azure-module).

## Development

If you have an issue with this module or would like to request a feature, [file a ticket](https://tickets.puppetlabs.com/browse/MODULES/).

If you have problems with this module, [contact Support](https://puppet.com/support-services/customer-support).
