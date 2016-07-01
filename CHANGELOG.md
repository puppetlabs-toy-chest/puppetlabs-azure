## Supported Version 1.0.3
### Summary
This release updates the module for the 0.3.0 version of the azure gems and
fixes a bug for Azure::Core

### Fixed
- Update to 0.3.0 version of azure\_mgmt\* gems
- Fix Azure::Core require
- Fix paging of REST when lots of VMs
- Fix puppet resource failing validation
- Fix docs mentioning incorrect quoting in azure.conf
- Fix bundlered listen gem failing on older rubies
- Fix lint warnings in examples/\*.pp
- Add Debian 8 to metadata
- Fix domain to be spec-specific

## Supported Version 1.0.2

This release includes:
* (CLOUD-488) Windows agent support for the Azure module testing.
* Several test improvements and fixes.
* Fixes validation for name length.
* Updates module for Hocon 1.0.0 compatibility.
* Improves error reporting.
* Adds apt-get update before install for custom_data param.

## 2015-12-08 - Supported Version 1.0.1

This release includes:

* Updates to the metadata to identify supported Windows platforms
* Improvements to the documentation around Windows support
* Fixes to URLs pointing at the previous Git repository

## 2015-12-08 - Supported Release 1.0.0

The first public release of the Azure module provides support for
managing VMs in both the Service Management (Classic) and new Resource
Management APIs in Azure.

