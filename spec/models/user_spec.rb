require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    it "is valid with sane attributes" do
      expect(build(:user)).to be_valid
    end

    it "requires an email" do
      user = build(:user, email: "")
      expect(user).not_to be_valid
      expect(user.errors[:email]).to be_present
    end

    it "rejects a malformed email" do
      user = build(:user, email: "not-an-email")
      expect(user).not_to be_valid
      expect(user.errors[:email]).to be_present
    end

    it "rejects a duplicate email, case-insensitively" do
      create(:user, email: "person@example.com")
      user = build(:user, email: "PERSON@example.com")
      expect(user).not_to be_valid
      expect(user.errors[:email]).to be_present
    end

    it "normalizes email to a stripped, downcased form" do
      user = create(:user, email: "  Person@Example.com  ")
      expect(user.email).to eq("person@example.com")
    end

    it "requires a password of at least 8 characters" do
      user = build(:user, password: "short", password_confirmation: "short")
      expect(user).not_to be_valid
      expect(user.errors[:password]).to be_present
    end

    it "does not require a password on update when it isn't being changed" do
      user = create(:user)
      user.email = "changed@example.com"
      expect(user).to be_valid
    end
  end

  describe "#authenticate" do
    it "returns the user for the correct password" do
      user = create(:user, password: "password123", password_confirmation: "password123")
      expect(user.authenticate("password123")).to eq(user)
    end

    it "returns false for the wrong password" do
      user = create(:user, password: "password123", password_confirmation: "password123")
      expect(user.authenticate("wrong")).to be false
    end
  end

  describe ".authenticate_by" do
    it "finds and authenticates in one call" do
      user = create(:user, email: "person@example.com", password: "password123", password_confirmation: "password123")
      expect(User.authenticate_by(email: "person@example.com", password: "password123")).to eq(user)
    end

    it "returns nil for a non-existent email" do
      expect(User.authenticate_by(email: "nobody@example.com", password: "password123")).to be_nil
    end
  end

  describe "password reset tokens" do
    it "generates a token that resolves back to the user" do
      user = create(:user)
      token = user.generate_token_for(:password_reset)
      expect(User.find_by_token_for(:password_reset, token)).to eq(user)
    end

    it "invalidates the token once the password changes (salted into the token)" do
      user = create(:user)
      token = user.generate_token_for(:password_reset)

      user.update!(password: "brand-new-password", password_confirmation: "brand-new-password")

      expect(User.find_by_token_for(:password_reset, token)).to be_nil
    end
  end

  describe "associations" do
    it "destroys sessions when the user is destroyed" do
      user = create(:user)
      session = user.sessions.create!
      user.destroy
      expect(Session.exists?(session.id)).to be false
    end
  end
end
