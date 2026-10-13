class DocumentPolicy < ApplicationPolicy
  # Documents: same rule as ActivityNotePolicy — any role except viewer can
  # attach/remove a document on any documentable, independent of that
  # documentable's own policy. See ActivityNotePolicy for why.
  def index? = true
  def show? = true
  def create? = !user.viewer?
  def update? = !user.viewer?
  def destroy? = !user.viewer?

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
