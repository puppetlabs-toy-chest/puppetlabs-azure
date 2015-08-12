[![Build
Status](https://magnum.travis-ci.com/puppetlabs/puppetlabs-msazure.svg?token=RqtxRv25TsPVz69Qso5L)](https://magnum.travis-ci.com/puppetlabs/puppetlabs-msazure)

####Table of Contents

1. [Overview](#overview)
2. [Description - What the module does and why it is useful](#module-description)
3. [Setup](#setup)
  * [Requirements](#requirements)
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
* Azure gem 0.7.0 or greater

### Installing the Azure module

1. Install the required gems with this command:

   ~~~
   /opt/puppet/bin/gem install azure --no-ri --no-rdoc --pre
   ~~~

   If you are running Puppet Enterprise 2015.2.0 you need to use the
updated path:

   ~~~
   /opt/puppetlabs/puppet/bin/gem install azure --pre --no-ri --no-rdoc
   ~~~

2. Set the following environment variables specific to your Azure
   installation:

   ~~~
   export AZURE_MANAGEMENT_CERTIFICATE='path-to-pem-file'
   export AZURE_SUBSCRIPTION_ID='your-subscription-id'
   ~~~

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
  ensure => 'present',
  image  => 'b39f27a8b8c64d52b05eac6a62ebad85__Ubuntu-14_04_2-LTS-amd64-server-20150706-en-us-30GB',
}
~~~


##Reference

###Types

* `azure_vm`: Manages a virtual machine in Microsoft Azure.

###Parameters

####Type: azure_vm

#####`ensure`
Specifies the basic state of the virtual machine. Valid values are
'present' and 'absent'. Defaults to 'present'.

#####`name`
*Required* The name of the virtual machine.

#####`image`
Name of the disk image to use to create the virtual machine.

#####`location`
The location where the virtual machine will be created.

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

#####`vm_size`
The size of the virtual machine instance.

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

#####`disks`
A list of disks which should be attached to the virtual machine.

#####`endpoints`
A list of endpoints which should be associated with the virtual machine.


##Limitations

This module is available only for Puppet Enterprise 3.8 and later.

## Known Issues


## Development

This module was built by Puppet Labs specifically for use with Puppet Enterprise (PE).

If you run into an issue with this module, or if you would like to request a feature, please [file a ticket](https://tickets.puppetlabs.com/browse/MODULES/).

If you have problems getting this module up and running, please [contact Support](http://puppetlabs.com/services/customer-support).
