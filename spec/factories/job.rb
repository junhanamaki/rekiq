require 'ice_cube'

FactoryGirl.define do
  factory :job, class: Rekiq::Job do
    work_time_shift 0
    schedule        IceCube::Schedule.new(Time.now + 3600)

    trait :randomized_attributes do
      schedule_post_work  [nil, false, true].sample
      work_time_shift     [*0..100].sample
      work_time_tolerance [*0..100].sample
      schedule_expired    [nil, false, true].sample
    end
  end
end