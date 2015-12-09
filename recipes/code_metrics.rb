case config['code_metrics']
  when 'simplecov'
    prefs[:code_metrics] = 'simplecov'
  when 'rubocop'
    prefs[:code_metrics] = 'rubocop'
end

if prefer :code_metrics, "simplecov"
  say_wizard "recipe adding code metrics gems"
  add_gem 'simplecov', group: :test, require: false

  stage_two do
    say_wizard "recipe stage two"

    if prefer :git, true
      append_to_file '.gitignore' do <<-GITIGNORE

# Ignore simplecov reports
coverage
GITIGNORE
      end
    end

    if prefer :tests, 'rspec'
      prepend_to_file 'spec/spec_helper.rb' do <<-RUBY
require 'simplecov'
SimpleCov.start 'rails'

RUBY
      end
    end
  end
end

__END__

name: code_metrics
description: "Rails metrics"
author: lunich

category: testing
requires: [setup, gems]
run_after: [git, setup, gems, tests]

config:
  - code_metrics:
      type: multiple_choice
      prompt: Add a code metrics mechanism?
      choices: [["None", "none"], ["SimpleCov", "simplecov"], ["RuboCop", "rubocop"]]
