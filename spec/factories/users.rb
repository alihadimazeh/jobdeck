FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }
    # Default role is admin (not viewer, the model's safe default for a
    # real unspecified signup) so the existing request/system spec suite's
    # global signed-in user keeps full access. Specs targeting a specific
    # role use the traits below.
    role { :admin }

    trait :viewer do
      role { :viewer }
    end

    trait :sales do
      role { :sales }
    end

    trait :project_manager do
      role { :project_manager }
    end

    trait :admin do
      role { :admin }
    end
  end
end
