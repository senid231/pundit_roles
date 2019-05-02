require 'active_support/concern'

module PunditRoles
  module ActiveAdminControllerPatch
    extend ActiveSupport::Concern

    include Pundit

    included do
      def pundit_user
        current_admin_user
      end

      protected

      # syntax sugar - skip action argument if it is equal to `params[:action].to_sym`
      # authorized? => authorized?(params[:action].to_sym, resource)
      # authorized?(record) => authorized?(params[:action].to_sym, record)
      def authorized?(action = nil, subject = nil)
        action, subject = normalize_authorized_params(action, subject)
        active_admin_authorization.authorized?(action, subject)
      end

      def authorize!(action = nil, subject = nil)
        action, subject = normalize_authorized_params(action, subject)
        unless authorized?(action, subject)
          raise ActiveAdmin::AccessDenied.new(current_active_admin_user, action, subject)
        end
      end

      private

      def normalize_authorized_params(action, subject)
        if subject.nil? && (!action.is_a?(Symbol) && !action.is_a?(String) && !action.is_a?(NilClass))
          subject = action
          action = nil
        end
        action = params[:action].to_sym if action.nil?
        subject = resource_class if subject.nil?
        [action, subject]
      end
    end

  end
end
