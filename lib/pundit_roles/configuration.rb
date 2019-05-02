require 'singleton'
require 'forwardable'

module PunditRoles
  class Configuration
    # Configuration object for PunditRoles.
    # Usage:
    #
    #   PunditRoles.configure do |config|
    #     config.roles_config = YAML.safe_load(Rais.root.join('config/roles.yml'))
    #     config.root_role = :my_root
    #     config.action_when_no_config = :disallow
    #     config.action_when_no_policy = :disallow
    #   end
    #
    #   PunditRoles::Configuration.action_when_no_config = :raise
    #   PunditRoles::Configuration.roles_config = YAML.safe_load(Rais.root.join('config/roles.yml'))
    #   PunditRoles::Configuration.root_role = :my_root
    #   PunditRoles::Configuration.action_when_no_config = :disallow
    #   PunditRoles::Configuration.action_when_no_policy = :disallow
    #
    #   PunditRoles::Configuration.root_role # :my_root
    #

    include Singleton

    extend SingleForwardable

    class << self
      def delegate_to_instance(*methods)
        def_delegators :instance, *methods
      end

      def define_key(name, allowed: nil, default: nil)
        var_name = "@#{name}"
        setter = "#{name}="
        attr_reader name
        # define_method(name) { instance_variable_get(var_name) }
        define_method(setter) do |value|
          if !allowed.nil? && !allowed.include?(value)
            raise ArgumentError,
                  "PunditRoles::Configuration.#{name} = #{value.inspect} is not one of #{allowed.join(', ')}"
          end
          instance_variable_set(var_name, value)
        end

        delegate_to_instance(name)
        instance.public_send(setter, default)
      end
    end

    define_key :roles_config
    define_key :root_role, default: :root
    define_key :action_when_no_config, allowed: [:raise, :allow, :disallow], default: :raise
    define_key :action_when_no_policy, allowed: [:raise, :allow, :disallow], default: :raise
  end
end
