class QuotePolicy < ApplicationPolicy
  # Quotes: full access for admin/project_manager/sales, read-only for viewer.
  def index? = true
  def show? = true
  def create? = !user.viewer?
  def update? = !user.viewer?
  def destroy? = !user.viewer?
  def accept? = update?

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
