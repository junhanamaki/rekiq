FactoryGirl.define do
  factory :configuration, class: Rekiq::Configuration do
    shift { [*-100..100].sample }
    schedule_post_work { [true, false].sample }
    expiration_margin  { [*0..100].sample }
    schedule_expired   { [true, false].sample }
  end
end