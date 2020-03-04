require 'active_support/concern'
require 'active_support/core_ext/array/extract_options'
require 'active_support/core_ext/hash/keys'
require 'active_support/core_ext/class/attribute'

module PunditRoles
  module DSL
    extend ActiveSupport::Concern

    included do
      class_attribute :_abstract, instance_accessor: false, default: false
      class_attribute :_section, instance_accessor: false
      class_attribute :_allowed_rules, instance_writer: false, default: %i[read change remove perform].freeze

      private :allowed_for_role?,
              :user_root?,
              :user_roles,
              :allow_when_no_config?,
              :section_name,
              :raise_when_no_config!,
              :raise_when_abstract!,
              :no_policy_class!,
              :no_policy_action!
    end

    class_methods do
      def inherited(subclass)
        subclass.section(nil)
        subclass.abstract(false)
        super
      end

      def alias_rule(*rule_names)
        options = rule_names.extract_options!
        options.assert_valid_keys(:to)
        raise ArgumentError, 'provide at least one rule name' if rule_names.empty?
        raise ArgumentError, 'to key is required' if options[:to].nil?

        rule_names.each do |rule_name|
          define_method(rule_name) do
            public_send(options[:to])
          end
        end
      end

      def allowed_rules(*rule_names)
        raise ArgumentError, 'required at least one argument' if rule_names.empty?
        self._allowed_rules = rule_names
      end

      def define_allowed_rules
        _allowed_rules.each do |rule_name|
          define_role_action(action: rule_name)
        end
      end

      def define_role_action(action:, rule: nil)
        define_method("#{action}?") do
          allowed_for_role?(rule || action)
        end
      end

      def section(section_name)
        self._section = section_name.try!(:to_sym)
      end

      def abstract(value = true)
        self._abstract = value
      end

      def abstract?
        !!self._abstract
      end
    end

    def allowed_for_role?(rule_name)
      return true if user_root?
      raise_when_no_config!
      raise_when_abstract!
      check_rule_allowed!(rule_name)
      roles_config = PunditRoles::Configuration.roles_config
      return allow_when_no_config? if roles_config.nil?

      user_allowed?(rule_name)
    end

    def check_rule_allowed!(rule_name)
      if _allowed_rules.exclude?(rule_name)
        raise ArgumentError, "#{rule_name} is not one of #{_allowed_rules}"
      end
    end

    def user_allowed?(rule_name)
      roles_config = PunditRoles::Configuration.roles_config
      roles = user_roles.map(&:to_sym)
      roles.any? { |role| roles_config.dig(role, section_name, rule_name) }
    end

    def user_root?
      raise NotImplementedError, 'implement me'
    end

    def user_roles
      raise NotImplementedError, 'implement me'
    end

    def allow_when_no_config?
      PunditRoles::Configuration.action_when_no_config == :allow
    end

    def section_name
      self.class._section || self.class.to_s[0...-6].gsub('::', '/').to_sym
    end

    def raise_when_no_config!
      raise_when_no_config = PunditRoles::Configuration.action_when_no_config == :raise
      roles_config = PunditRoles::Configuration.roles_config
      raise PunditRoles::Errors::NoConfigError if roles_config.nil? && raise_when_no_config
    end

    def raise_when_abstract!
      raise PunditRoles::Errors::AbstractPolicyError if self.class.abstract?
    end

    def no_policy_class!
      raise_when_no_config!
      raise_when_abstract!

      record_class = record.is_a?(Class) ? record : record.class
      rule = PunditRoles::Configuration.action_when_no_policy_class
      logger.debug { "[POLICY WARNING] missing policy class for #{record_class}." }
      case rule.to_sym
      when :allow then
        true
      when :disallow then
        false
      when :raise then
        raise PunditRoles::Errors::MissingPolicyClassError, record_class
      end
    end

    def no_policy_action!(action_name)
      raise_when_no_config!
      raise_when_abstract!

      record_class = record.is_a?(Class) ? record : record.class
      rule = PunditRoles::Configuration.action_when_no_policy_action
      logger.debug { "[POLICY WARNING] missing policy action #{action_name} for #{self.class}." }
      case rule.to_sym
      when :allow then
        true
      when :disallow then
        false
      when :raise then
        raise PunditRoles::Errors::MissingPolicyActionError, "missing policy class for #{record_class}."
      end
    end

  end
end
