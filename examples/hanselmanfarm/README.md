This example is based on Scott Hanselman's blog post ["How to setup a Load Balanced Web Farm of Virtual Machines"](http://www.hanselman.com/blog/HowToSetupALoadBalancedWebFarmOfVirtualMachinesLinuxOrOtherwiseOnWindowsAzureCommandLine.aspx).

To run this, please change the `cloud_service` name in the manifest and execute it using `puppet apply init_simple.pp` after installing the module and configuring credentials as described in the top-level README. After successful application, you can access the web servicer as http://CLOUDSERVICENAME.cloudapp.net .

Deviating from the blog post, this example does not use a custom image. Instead, one of the provided default images is used together with Azure's cloud-init support to configure it on its first boot. A more complex setup would install and configure a puppet agent (either on provisioning or within a custom image) and use that to apply further customizations.

Please see the code comments in the manifest files for the technical details.
