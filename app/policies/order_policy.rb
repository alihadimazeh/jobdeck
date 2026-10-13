class OrderPolicy < ApplicationPolicy
  # Orders: full access for admin/project_manager, read-only for sales/viewer.
  def index? = true
  def show? = true
  def create? = user.admin? || user.project_manager?
  def update? = user.admin? || user.project_manager?
  def destroy? = user.admin? || user.project_manager?

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
