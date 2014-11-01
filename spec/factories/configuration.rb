FactoryGirl.define do
  factory :configuration, class: Rekiq::Configuration do
    schedule_post_work  [true, false].sample
    work_time_shift     [*-100..100].sample
    work_time_tolerance [*0..100].sample
    schedule_expired    [true, false].sample
  end
end