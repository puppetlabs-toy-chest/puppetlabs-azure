[![Build
Status](https://magnum.travis-ci.com/puppetlabs/puppetlabs-msazure.svg?token=RqtxRv25TsPVz69Qso5L)](https://magnum.travis-ci.com/puppetlabs/puppetlabs-msazure)

####Table of Contents

1. [Overview](#overview)
2. [Description - What the module does and why it is useful](#module-description)
3. [Setup](#setup)
  * [Requirements](#requirements)
  * [Getting Azure credentials](#getting-azure-credentials)
  * [Installing the Azure module](#installing-the-azure-module)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
  * [Types](#types)
  * [Parameters](#parameters)
6. [Known Issues](#known-issues)
7. [Limitations - OS compatibility, etc.](#limitations)

## Overview


## Description

## Setup

### Requirements

* Puppet Enterprise 3.8 or greater
* [Azure gem](https://rubygems.org/gems/azure) 0.7.0 or greater

### Getting Azure credentials

In order to use the Azure module you'll need an Azure account. If you
already have one you can skip this section, but otherwise you can sign
up for a [Free Trial](http://azure.microsoft.com/en-gb/).

You then need to install the Azure CLI. This is required to
generate the certificate that we will use later for the Puppet module
but it's also a useful way of interacting with Azure. Follow this
[installation
guide](https://azure.microsoft.com/en-gb/documentation/articles/xplat-cli-install/)
on how to get the CLI setup.

Next you need to register the CLI with your Azure account. You can do
this by following this [guide from
Microsoft](https://azure.microsoft.com/en-gb/documentation/articles/xplat-cli-connect/).
The basic steps are:

~~~
azure account download
azure account import <path to your .publishsettings file>
~~~

Once you have the account created you can export the PEM certificate file
using the following command:

~~~
azure account cert export
~~~

And finally you can get the subscription ID using the `account list` command
like so:

~~~
$ azure account list
info:    Executing command account list
data:    Name                    Id                                     Tenant Id  Current
data:    ----------------------  -------------------------------------  ---------  -------
data:    Pay-As-You-Go           xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxxx  undefined  true
info:    account list command OK
~~~

### Installing the Azure module

1. Install the required gems with this command:

   ~~~
   /opt/puppet/bin/gem install azure hocon retries --no-ri --no-rdoc
   ~~~

   If you are running Puppet Enterprise 2015.2.0 you need to use the
updated path:

   ~~~
   /opt/puppetlabs/puppet/bin/gem install azure hocon retries --no-ri --no-rdoc
   ~~~

2. Set the following environment variables specific to your Azure
   installation:

   ~~~
   export AZURE_MANAGEMENT_CERTIFICATE='/path/to/pem/file'
   export AZURE_SUBSCRIPTION_ID='your-subscription-id'
   ~~~

   Alternatively, you can provide the information in a configuration file. Store this as azure.conf in the relevant [confdir](https://docs.puppetlabs.com/puppet/latest/reference/dirs_confdir.html). This should be:

   * nix Systems: /etc/puppetlabs/puppet
   * Windows: C:\ProgramData\PuppetLabs\puppet\etc
   * non-root users: ~/.puppetlabs/etc/puppet

   The file format is:

   ~~~
   azure: {
     subscription_id: "your-subscription-id"
     management_certificate: "/path/to/pem/file"
   }
   ~~~

   Note that you can use either the environment variables or the config file. If both are present the environment variables will be used. You cannot have some settings in environment variables and others in the config file.

3. Finally install the module with:

   ~~~
   puppet module install puppetlabs-msazure
   ~~~


## Usage

You can create Azure Virtual Machines using the following:

~~~
azure_vm { 'virtual-machine-name':
  ensure           => present,
  image            => 'b39f27a8b8c64d52b05eac6a62ebad85__Ubuntu-14_04_2-LTS-amd64-server-20150706-en-us-30GB',
  location         => 'West US',
  user             => 'username',
  size             => 'Medium',
  private_key_file => '/path/to/private/key',
}
~~~

In addition to describing new machines using the DSL the module also supports
listing and managing machines via `puppet resource`:

~~~
puppet resource azure_vm
~~~

Note that this will output some information about the machines in your
account:

~~~
azure_vm { 'virtual-machine-name':
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


##Reference

###Types

* `azure_vm`: Manages a virtual machine in Microsoft Azure.

###Parameters

####Type: azure_vm

#####`ensure`
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

#####`name`
*Required* The name of the virtual machine.

#####`image`
Name of the image to use to create the virtual machine. This can be either a VM Image or an OS Image. When specifying a VM Image, `user`, `password`, and `private_key_file` are not used.

#####`location`
*Required* The location where the virtual machine will be created. Details of
available values can be found on the [Azure
regions documentation](http://azure.microsoft.com/en-gb/regions/).
Location is read-only once the VM has been created.

#####`user`
The name of the user to be created on the virtual machine. Required for Linux guests.

#####`password`
The password for the above mentioned user on the virtual machine.

#####`private_key_file`
Path to the private key file for accessing a Linux guest as the above
user.

#####`storage_account`
The storage account to associate the virtual machine with.

#####`winrm_transport`
A list of transport protocols for WINRM.

#####`winrm_https_port`
The port number of WINRM https communication.

#####`winrm_http_port`
The port number of WINRM http communication.

#####`cloud_service`
The name of the associated cloud service.

#####`deployment`
The name for the deployment.

#####`ssh_port`
The port number for SSH.

#####`size`
The size of the virtual machine instance. See the Azure documentation
for a [full list of
sizes](https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-size-specs/).

#####`affinity_group`
The affinity group to be used for the cloud service and the storage account if these do not exist.

#####`virtual_network`
The virtual network to which the virtual machine should be connected.

#####`subnet`
The subnet to which the virtual machine should be associated.

#####`availability_set`
The availability set for the virtual machine.

#####`reserved_ip`
The name of the reserved IP to associate with the virtual machine.

#####`data_disk_size_gb`
The size of the data disk for this virtual machine, specified in gigabytes. Over the life cycle of a disk, this size
can only grow. If this value is not set, puppet will not touch the data disks for this virtual machine.

#####`purge_disk_on_delete`
Whether or not the attached data disk should be deleted when the VM is deleted. Defaults to false.

#####`endpoints`
A list of endpoints which should be associated with the virtual machine.

#####`os_type`
_Read Only_. The operating system type for the virtual machine.

#####`ipaddress`
_Read Only_. The IP address assigned to the virtual machine.

#####`hostname`
_Read Only_. The hostname of the running virtual machine.

#####`media_link`
_Read Only_. The link to the underlying disk image for the virtual
machine.


##Limitations

This module is available only for Puppet Enterprise 3.8 and later.

## Known Issues


## Development

This module was built by Puppet Labs specifically for use with Puppet Enterprise (PE).

If you run into an issue with this module, or if you would like to request a feature, please [file a ticket](https://tickets.puppetlabs.com/browse/MODULES/).

If you have problems getting this module up and running, please [contact Support](http://puppetlabs.com/services/customer-support).
