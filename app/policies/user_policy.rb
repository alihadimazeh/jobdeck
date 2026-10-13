class UserPolicy < ApplicationPolicy
  # User management: admin only. No controller uses this yet (no
  # user-management UI exists), but the rule is already the one CLAUDE.md
  # commits to, so it's correct the moment that UI lands.
  def index? = user.admin?
  def show? = user.admin?
  def create? = user.admin?
  def update? = user.admin?
  def destroy? = user.admin?

  class Scope < ApplicationPolicy::Scope
    def resolve
      user.admin? ? scope.all : scope.none
    end
  end
end
