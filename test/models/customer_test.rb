require "test_helper"

class CustomerTest < ActiveSupport::TestCase
  test "status defaults to active" do
    customer = customers(:one)
    assert customer.active_status?
  end

  test "status accepts inactive" do
    customer = customers(:one)
    customer.status = "inactive"
    assert customer.valid?
    assert customer.inactive_status?
  end

  test "status accepts archived" do
    customer = customers(:one)
    customer.status = "archived"
    assert customer.valid?
    assert customer.archived_status?
  end

  test "status rejects values outside the enum" do
    customer = customers(:one)
    assert_raises(ArgumentError) { customer.status = "bogus" }
  end

  test "status must be present" do
    customer = customers(:one)
    customer.status = nil
    assert_not customer.valid?
    assert_includes customer.errors[:status], "can't be blank"
  end
end
