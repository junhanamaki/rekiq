require 'ice_cube'

FactoryGirl.define do
  factory :job, class: Rekiq::Job do
    shift    0
    schedule { IceCube::Schedule.new(Time.now + 3600) }

    trait :randomized_attributes do
      shift              { [*0..100].sample }
      schedule_post_work { [nil, false, true].sample }
      schedule_expired   { [nil, false, true].sample }
      expiration_margin  { [*0..100].sample }
    end
  end
end