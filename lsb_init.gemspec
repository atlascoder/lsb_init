Gem::Specification.new do |s|
  s.name        = 'lsb_init'
  s.version     = '0.0.5'
  s.executables << 'lsb_init_ruby'
  s.date        = '2016-09-22'
  s.summary     = 'lsb-init is a tool for generating LSB Init scripts for Ruby projects deploying in Debian systems'
  s.description = 'Gem provides commands to generate/remove `/etc/init.d/service_script` for single-instanced daemon'
  s.authors     = ['Anton Titkov']
  s.email       = 'atlascoder@gmail.com'
  s.files       = ['lib/lsb_init/configurator.rb', 'lib/daemon', 'lib/lsb_init/main.rb']
  s.homepage    ='http://github.com/atlascoder/lsb_init'
  s.license     = 'MIT'
end
