spec = Gem::Specification.new do |s|
  s.name = 'vm_perftools.rb'
  s.version = '0.1.8'
  s.date = '2010-12-22'
  s.summary = 'google-perftools for ruby vm code'
  s.description = 'A sampling profiler for ruby vm code based on google-perftools'

  s.homepage = "http://github.com/tmm1/perftools.rb"

  s.authors = ["Aman Gupta"]
  s.email = "perftools@tmm1.net"

  s.has_rdoc = false
  s.extensions = 'ext/extconf.rb'
  s.bindir = 'bin'
  s.executables << 'pprof.rb'

  # ruby -rpp -e' pp `git ls-files | grep -v examples`.split("\n").sort '
  s.files = `git ls-files`.split("\n").reject{ |f| f =~ /^examples/ }
end
