stage_three do
  say_wizard 'recipe stage three'

  copy_file("#{ destination_root }/config/environments/production.rb", "#{ destination_root }/config/environments/staging.rb")

  if prefer(:git, true)
    git(:add => 'config/environments/staging.rb')
    git(:commit => '-qm "rails_apps_composer: added staging environment"')
  end
end

__END__

name: staging_env
description: "Adds staging environment"
author: kryachkov.andrey@gmail.com

category: testing
run_after: [reset_smtp_settings]
