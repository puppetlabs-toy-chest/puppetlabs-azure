require 'master_manipulator'
test_name 'Install Puppet Enterprise'

# Cloud Provisioner is rarely installed by customers but Beaker defaults
# to installing it, which masks issues due to that package installing
# nokogiri
@hosts.each do |host|
  host[:custom_answers] ||= {}
  host[:custom_answers][:q_puppet_cloud_install] = 'n'
end

# Init
options[:version] = ENV['PUPPET_AGENT_VERSION'] || '1.2.0'
options[:sha] = ENV['PUPPET_AGENT_VERSION'] || '1.2.0'

step 'Install PE'
install_pe

step 'Disable Node Classifier'
disable_node_classifier(master)

step 'Disable environment caching'
disable_env_cache(master)

step 'Restart Puppet Server'
restart_puppet_server(master)

