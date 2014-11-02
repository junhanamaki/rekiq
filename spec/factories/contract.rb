require 'ice_cube'

FactoryGirl.define do
  factory :contract, class: Rekiq::Contract do
    work_time_shift 0
    schedule        IceCube::Schedule.new(Time.now + 3600)

    trait :randomized_attributes do
      cancel_args         [nil, 'asd', ['d', 'dsa']].sample
      addon               [nil, '2121', 'dasdas'].sample
      schedule_post_work  [nil, false, true].sample
      work_time_shift     [nil, *0..100].sample
      work_time_tolerance [nil, *0..100].sample
      schedule_expired    [nil, false, true].sample
    end
  end
end