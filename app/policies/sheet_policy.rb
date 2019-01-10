class SheetPolicy < ApplicationPolicy
  attr_reader :user, :sheet

  def initialize(user, sheet)
    # not really interested in the sheet
    @user = user
    @sheet = sheet
  end

  def query?
  end

  def index?
  end

  def show?
  end

  def create?
    @user && @user.role=='admin'
  end

  def new?
    create?
  end

  def update?
    @user && @user.role=='admin'
  end

  def edit?
    update?
  end

  def destroy?
    @user && @user.role=='admin'
  end

  def scope
    Pundit.policy_scope!(user, sheet.class)
  end

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
end
