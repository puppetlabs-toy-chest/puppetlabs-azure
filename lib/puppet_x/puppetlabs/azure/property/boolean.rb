module PuppetX
  module PuppetLabs
    module Azure
      module Property
        class Boolean < Puppet::Property
          validate do |value|
            fail "#{self.name.to_s} should be a Boolean" unless !!value == value
          end
        end
      end
    end
  end
end
