# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rubocop/rake_task'

task :lint do
  RuboCop::RakeTask.new(:rubocop)
  Rake::Task['rubocop'].invoke
end
