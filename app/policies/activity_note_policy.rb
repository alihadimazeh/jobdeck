class ActivityNotePolicy < ApplicationPolicy
  # Notes: any role except viewer can add/edit/remove a note on any notable
  # (Customer, Lead, Job, or Order) — deliberately independent of that
  # notable's own policy, so e.g. sales (read-only on Job) can still log a
  # note on one. There's no per-user ownership yet (the `author` column is
  # free text, not a user_id), so this can't be narrowed to "your own notes."
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
