require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and trim email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "valid with a proper email and password" do
    user = User.new(email_address: "new@example.com", password: "password123")
    assert user.valid?
  end

  test "invalid with a malformed email" do
    user = User.new(email_address: "not-an-email", password: "password123")
    assert_not user.valid?
  end

  test "invalid with a duplicate email" do
    existing = users(:one)
    user = User.new(email_address: existing.email_address.upcase, password: "password123")
    assert_not user.valid?
  end

  test "invalid with a short password" do
    user = User.new(email_address: "short@example.com", password: "short")
    assert_not user.valid?
  end

  test "normalizes email to lowercase" do
    user = User.create!(email_address: "MixedCase@Example.com", password: "password123")
    assert_equal "mixedcase@example.com", user.email_address
  end
end
