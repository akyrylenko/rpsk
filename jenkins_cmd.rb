require "jenkins_api_client"
require 'optparse'
require 'optparse/time'

jenkins_options = {
  default_project_name: "NewAPICreatedRailsJob",
  project_name: 'TestProject',
  jenkins_url: 'http://localhost:8080/',
  jenkins_user_id: '',
  jenkins_api_token: '',
  ruby_gemset: 'testgenerator',
  ruby_version: '2.2.2',
  githut_path: 'akyrylenko/testgenerator',
  github_url: 'git@github.com:akyrylenko/testgenerator.git',
  user_fullname: nil,
  user_email: nil,
  setup_gemsurance_job: true,
  setup_rails_best_practices_job: true,
  setup_brakeman_job: true,
  setup_rubocop_job: true,
}

OptionParser.new do |parser|
  parser.on("--project-name [PROJECT_NAME]", String, "Name of the project") do |_project_name|
    p 'Project Name:', _project_name
    jenkins_options[:project_name] = _project_name
  end
  parser.on("--jenkins-url [JENKINS_URL]", String, "Jenkins URL") do |_jenkins_url|
    p 'Jenkins URL:', _jenkins_url
    jenkins_options[:jenkins_url] = _jenkins_url
  end
  parser.on("--jenkins-user-id [JENKINS_USER_ID]", String, "Jenkins UserID") do |_jenkins_user_id|
    p 'Jenkins UserID:', _jenkins_user_id
    jenkins_options[:jenkins_user_id] = _jenkins_user_id
  end
  parser.on("--jenkins-api-token [JENKINS_API_TOKEN]", String, "Jenkins API Token") do |_jenkins_api_token|
    p 'Jenkins API Token:', _jenkins_api_token
    jenkins_options[:jenkins_api_token] = _jenkins_api_token
  end
  parser.on("--ruby-version [RUBY]", String, "Ruby Version") do |_ruby_version|
    p 'Ruby Version:', _ruby_version
    jenkins_options[:ruby_version] = _ruby_version
  end
  parser.on("--ruby-gemset [GEMSET]", String, "Ruby GemSet") do |_ruby_gemset|
    p 'Ruby GemSet:', _ruby_gemset
    jenkins_options[:ruby_gemset] = _ruby_gemset
  end
  parser.on("--github-url [GITHUB_URL]", String, "GitHub URL") do |_github_url|
    p 'GitHub URL:', _github_url
    jenkins_options[:github_url] = _github_url
  end
  parser.on("--github-path [GITHUB_PATH]", String, "GitHub Path") do |_githut_path|
    p 'GitHub Path:', _githut_path
    jenkins_options[:githut_path] = _githut_path
  end
  parser.on("--user-fullname [USER_FULLNAME]", String, "User FullName") do |_user_fullname|
    p 'User FullName:', _user_fullname
    jenkins_options[:user_fullname] = _user_fullname
  end
  parser.on("--user-email [USER_EMAIL]", String, "User Email") do |_user_email|
    p 'User Email:', _user_email
    jenkins_options[:user_email] = _user_email
  end
  # You may not need this if set "Skip internal tag" checkbox in "Source Code Management" section
  # or you can
  # go to "Manage Jenkins" > "Configure System" and scroll down to "Git plugin" and there you will find 
  # Global Config user.name Value
  # Global Config user.email Value

  parser.on("--setup-brakeman-job [BRAKEMAN_JOB]", String, "Setup Brakeman Job") do |_setup_brakeman_job|
    p 'Setup Brakeman Job:', _setup_brakeman_job
    jenkins_options[:setup_brakeman_job] = _setup_brakeman_job
  end
  parser.on("--setup-gemsurance-job [GEMSURANCE_JOB]", String, "Setup Gemsurance Job") do |_setup_gemsurance_job|
    p 'Setup Gemsurance Job:', _setup_gemsurance_job
    jenkins_options[:setup_gemsurance_job] = _setup_gemsurance_job
  end
  parser.on("--setup-rails-best-practices-job [BEST_PRACTICES_JOB]", String, "Setup Rails Best Practices Job") do |_setup_rails_best_practices_job|
    p 'Setup Rails Best Practices Job:', _setup_rails_best_practices_job
    jenkins_options[:setup_rails_best_practices_job] = _setup_rails_best_practices_job
  end
  parser.on("--setup-rubocop-job [RUBOCOP_JOB]", String, "Setup Rubocop Job") do |_setup_rails_best_practices_job|
    p 'Setup Rails Best Practices Job:', _setup_rails_best_practices_job
    jenkins_options[:setup_rails_best_practices_job] = _setup_rails_best_practices_job
  end
##  parser.on("-t", "--time [TIME]", Time, "Begin execution at given time") do |time|
##    p 'time:', time
##  end
end.parse!

module JenkinsJobSetup
  class Creator
    def initialize(options={})
      @options = options
    end

    def process
      self.connect
      self.prepare_project_name
      self.create_jobs
    end

    def connect
      jenkins_api_client_options = {server_url: @options[:jenkins_url]}
      jenkins_api_client_options.merge!(username: @options[:jenkins_user_id]) unless @options[:jenkins_user_id].nil? || @options[:jenkins_user_id].empty?
      jenkins_api_client_options.merge!(password: @options[:jenkins_api_token]) unless @options[:jenkins_api_token].nil? || @options[:jenkins_api_token].empty?
      @client = JenkinsApi::Client.new(jenkins_api_client_options)
    end

    def prepare_project_name
      if @options[:project_name].nil?
        jobs = @client.job.list("^" + @options[:default_project_name])
        #jobs = @client.job.list_all
        @options[:project_name] = [@options[:default_project_name], jobs.count].join('-')
      end
    end

    def prepare_git_settings_sh
      <<-SETUP_GIT_SETTINGS

      SETUP_GIT_SETTINGS
    end

    def sh_header
      "#!/bin/bash" + <<-SHELL_HEADER

      SHELL_HEADER
    end

    def prepare_ruby_gemset
      <<-RUBY_GEM_SET_SH
        source ~/.bash_profile
        #{prepare_git_settings_sh}
        rvm install #{@options[:ruby_version]}
        rvm use #{@options[:ruby_version]}@#{@options[:ruby_gemset]} --create
        gem install bundler --no-ri --no-rdoc
        bundle install --quiet
      RUBY_GEM_SET_SH
    end

    def clear_logs
      "rm -rf log/*"
    end

    def setup_application
      <<-SETUP_APPLICATION_SH
        cp config/deploy/ci/*.yml config/
        bundle exec rake db:create
        bundle exec rake db:migrate
        bundle exec rake db:test:prepare
      SETUP_APPLICATION_SH
    end

    def regenerate_assets
      <<-GENERATE_ASSETS
        rm -rf public/assets/
        jammit
      GENERATE_ASSETS
    end

    def rails_best_practices
      <<-RAILS_BEST_PRACTICES_SH
        RAILS_ENV=test COVERAGE=on bundle exec rake ci:setup:rspecdoc spec
        bundle exec rails_best_practices --silent -f html --with-github #{@options[:githut_path]} . || true
      RAILS_BEST_PRACTICES_SH
    end

    def brakeman_commands
      <<-BRAKEMAN_SH
        gem install brakeman --no-ri --no-rdoc
        bundle exec brakeman -q . -o brakeman-report.html
        bundle exec brakeman -q -o brakeman-output.tabs --no-progress --separate-models
      BRAKEMAN_SH
    end

    def gemsurance_command
      <<-GEMSURANCE_SH
        bundle exec gemsurance
      GEMSURANCE_SH
    end

    def rubocop_command
      <<-RUBOCOP_SH
        bundle exec rubocop --require rubocop/formatter/checkstyle_formatter --format RuboCop::Formatter::CheckstyleFormatter --no-color --rails --out tmp/rubocop_checkstyle.xml -c rubocop.yml || true
      RUBOCOP_SH
    end

    def start_commands
      [
        sh_header,
        prepare_ruby_gemset,
        clear_logs,
        setup_application,
      ]
    end

    def shell_commands
      {
        gemsurance: [gemsurance_command],
        rails_best_practices: [rails_best_practices],
        brakeman: [brakeman_commands],
        rubocop: [rubocop_command],
      }
    end

    def job_template_name
      '-JOB-NAME-'
    end

    def job_descriptions
      {
        gemsurance: ['Gemsurance report', "#{@options[:jenkins_url]}/job/#{job_template_name}/ws/gemsurance_report.html"],
        rails_best_practices: ['Rails Best Practices report', "#{@options[:jenkins_url]}/job/#{job_template_name}/ws/rails_best_practices_output.html"],
        brakeman: ['Brakeman report', "#{@options[:jenkins_url]}/job/#{job_template_name}/ws/brakeman-report.html"],
        rubocop: ['Rubocop analisys'],
      }
    end

    def create_jobs
      build_jobs_names = []
      shell_commands.each_pair do |_job_name, shell_command|
        job_name = [@options[:project_name], _job_name].join('-')

        job_description = job_descriptions[_job_name.to_sym].join("\n").split('//').join('/').split(job_template_name).join(job_name)
        _shell_commands = (start_commands + shell_command).join("\n")

        _options = {
          "NEW_JOB_NAME" => job_name,
          "NEW_JOB_DESCRIPTION" => job_description,
          "NEW_JOB_GITHUB_URL" => @options[:github_url],
          "NEW_JOB_SHELL_COMMANDS1" => _shell_commands,
        }

        job_code = @client.job.build("BuildRailsShellJobFromAPI", _options)
        unless job_code == '201'
          raise "Could not build the job specified" 
        else
          build_jobs_names << job_name
        end
      end
      puts "Build #{build_jobs_names.size} jobs on @options[:jenkins_url]:\n#{build_jobs_names.map{|j| "- #{j}"}.join(";\n")}.\n"
    end
  end
end

jenkins_job_set_creator = JenkinsJobSetup::Creator.new(jenkins_options)
jenkins_job_set_creator.process