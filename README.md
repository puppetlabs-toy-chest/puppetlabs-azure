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


### Installing the Azure module


## Usage


##Reference

###Types

* `azure_vm`: Manages a virtual machine in Microsoft Azure.

###Parameters

####Type: azure_vm

#####`ensure`

#####`name`
*Required* The name of the virtual machine.

#####`user`
The user name for the virtual machine.

#####`image`
Name of the disk image to use to create the virtual machine.

#####`password`
The password for the virtual machine.

#####`location`
The location where the virtual machine will be created.

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

#####`tcp_endpoints`
The internal port and external/public port separated by a colon.

#####`private_key_file`
Path to the private key file.

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
