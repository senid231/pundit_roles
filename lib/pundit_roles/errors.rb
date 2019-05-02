module PunditRoles
  module Errors
    class Error < ::StandardError
    end

    class NoConfigError < Error
      def initialize
        super('roles config missing.')
      end
    end

    class AbstractPolicyError < Error
      def initialize
        super("action can't be checked for abstract rule")
      end
    end

    class MissingPolicyClassError < Error
      def initialize(record_class)
        super("missing policy class for #{record_class}.")
      end
    end

    class MissingPolicyActionError < Error
      def initialize(record_class)
        super("missing policy class for #{record_class}.")
      end
    end
  end
end
