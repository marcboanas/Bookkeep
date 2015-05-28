FactoryGirl.define do
  factory :user do
    first_name 'Example'
    last_name 'User'
    email 'example@user.com'
    password 'Password123'
    password_confirmation 'Password123'
  end
  factory :receipt do
    title 'Test'
    image_name 'Test'
    image_url 'http://www.test.com/123'
    random_id '12345678987654321234'
  end
end
