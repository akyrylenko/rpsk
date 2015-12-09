stage_three do
  gsub_file(
    'config/environments/production.rb',
    /"smtp.gmail.com"/,
    'Rails.application.secrets.smtp_address'
  )
  gsub_file(
    'config/environments/production.rb',
    /587/,
    'Rails.application.secrets.smtp_port'
  )
  gsub_file(
    'config/environments/production.rb',
    /"plain"/,
    'Rails.application.secrets.smtp_authentication'
  )
  gsub_file(
    'config/environments/production.rb',
    /enable_starttls_auto: true/,
    'enable_starttls_auto: Rails.application.secrets.smtp_enable_starttls_auto'
  )
  gsub_file(
    'config/environments/production.rb',
    /Rails.application.secrets.email_provider_password/,
    'Rails.application.secrets.smtp_password,'
  )
  gsub_file(
    'config/environments/production.rb',
    /domain: Rails.application.secrets.domain_name/,
    'domain: Rails.application.secrets.smtp_domain'
  )
  gsub_file(
    'config/environments/production.rb',
    /email_provider_username/,
    'smtp_user_name'
  )
  insert_into_file(
    'config/environments/production.rb',
    "\n    openssl_verify_mode: Rails.application.secrets.smtp_openssl_verify_mode",
    :after => 'Rails.application.secrets.smtp_password,'
  )

  gsub_file(
    'config/initializers/devise.rb',
    /config.mailer_sender = 'no-reply@' \+ Rails.application.secrets.domain_name/,
    'config.mailer_sender = Rails.application.secrets.mailer_default_from'
  )

  if prefer(:git, true)
    git(:add => 'config/environments/production.rb config/initializers/devise.rb')
    git(:commit => '-qm "rails_apps_composer: reseted stmp settings"')
  end
end


__END__

name: reset_smtp_settings
description: "Reset smtp settings provided by rails_apps_composer"
author: kryachkov.andrey@gmail.com

category: other
requires: []
run_after: [init]
