copy_from_repo('.rubocop.yml', :repo => 'https://raw.githubusercontent.com/Gera-IT/gerait_rubocop_config/master/')

if prefer(:git, true)
  git(:add => '.rubocop.yml')
  git(:commit => '-qm "rails_apps_composer: added .rubocop.yml"')
end

__END__

name: gerait_rubocop_config
description: "Adds Gera's .rubocop.yml"
author: kryachkov.andrey@gmail.com

category: other
requires: []
run_after: [extras, gems, init]
