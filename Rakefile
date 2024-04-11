# frozen_string_literal: true

require 'bundler/gem_tasks'
require "rspec/core/rake_task"
require 'rubocop/rake_task'

task :lint do
  RuboCop::RakeTask.new(:rubocop)
  Rake::Task['rubocop'].invoke
end

task :test do
  RSpec::Core::RakeTask.new(:spec)
  Rake::Task['spec'].invoke
end
