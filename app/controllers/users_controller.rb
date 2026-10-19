class UsersController < ApplicationController
  before_action :set_user, only: %i[ show edit update ]

  # GET /users
  def index
    authorize User
    @users = policy_scope(User).order(:id)
  end

  # GET /users/1
  def show
    authorize @user
  end

  # GET /users/new
  def new
    @user = User.new
    authorize @user
  end

  # GET /users/1/edit
  def edit
    authorize @user
  end

  # POST /users
  def create
    @user = User.new(user_params)
    # has_secure_password requires a password on create and password_digest is
    # NOT NULL - an admin never sets one directly, so generate a throwaway
    # value nobody is ever shown and email an invite link to set a real one.
    random_password = SecureRandom.alphanumeric(20)
    @user.password = @user.password_confirmation = random_password
    authorize @user

    if @user.save
      UsersMailer.invite(@user).deliver_later
      redirect_to @user, notice: "User was successfully created. An invite email was sent to #{@user.email}."
    else
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /users/1
  def update
    authorize @user

    if @user == current_user && user_params[:role].present? && user_params[:role] != current_user.role
      @user.errors.add(:role, "can't be changed on your own account")
      return render :edit, status: :unprocessable_content
    end

    if @user.update(user_params)
      redirect_to @user, notice: "User was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  # Email + role only - an admin never sets or sees a user's password.
  def user_params
    params.require(:user).permit(:email, :role)
  end
end
