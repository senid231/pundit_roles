module PunditRoles
  class RolesPolicy
    class Scope
      attr_reader :user, :scope

      def initialize(user, scope)
        @user = user
        @scope = scope
      end

      def resolve
        scope
      end
    end

    include PunditRoles::DSL
    abstract

    attr_reader :user, :record

    def initialize(user, record)
      @user = user
      @record = record
    end

    def scope
      Pundit.policy_scope!(user, record.class)
    end

  end
end
