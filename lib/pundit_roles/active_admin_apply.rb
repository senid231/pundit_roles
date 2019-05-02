require 'active_admin/base_controller'
require 'pundit_roles/active_admin_controller_patch'

ActiveAdmin::BaseController.include PunditRoles::ActiveAdminControllerPatch

ActiveAdmin.setup do |config|
  config.authorization_adapter = ActiveAdmin::PunditAdapter
  # config.pundit_default_policy = 'DefaultApplicationPolicy'
end
