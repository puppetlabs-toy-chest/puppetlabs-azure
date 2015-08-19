test_name "Install nokogiri dependencies for RedHat"
confine :to, :platform => ['el-6-x86_64', 'el-7-x86_64']
agents.each do |agent|
    on(agent, 'yum install zlib-devel patch -y')
end
