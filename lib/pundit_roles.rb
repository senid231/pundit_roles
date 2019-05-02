require 'pundit_roles/version'
require 'pundit_roles/configuration'
require 'pundit_roles/dsl'
require 'pundit_roles/roles_policy'

module PunditRoles
  def self.configure
    yield(PunditRoles::Configuration.instance)
  end
end
