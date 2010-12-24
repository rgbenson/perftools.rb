CWD = File.expand_path(File.dirname(__FILE__))

def sys(cmd)
  puts "  -- #{cmd}"
  unless ret = xsystem(cmd)
    raise "#{cmd} failed, please report to perftools@tmm1.net with pastie.org link to #{CWD}/mkmf.log and #{CWD}/src/google-perftools-1.6/config.log"
  end
  ret
end

require 'mkmf'
require 'fileutils'

perftools = File.basename('google-perftools-1.6.tar.gz')
dir = File.basename(perftools, '.tar.gz')

puts "(I'm about to compile google-perftools.. this will definitely take a while)"
ENV["PATCH_GET"] = '0'

Dir.chdir('src') do
  FileUtils.rm_rf(dir) if File.exists?(dir)

  sys("tar zxvf #{perftools}")
  Dir.chdir(dir) do
    if ENV['DEV']
      sys("git init")
      sys("git add .")
      sys("git commit -m 'initial source'")
    end

    [ ['perftools-notests', true],
      ['perftools-pprof', true],
      ['perftools-gc', true],
    ].each do |patch, apply|
      if apply
        sys("patch -p1 < ../../../patches/#{patch}.patch")
        sys("git commit -am '#{patch}'") if ENV['DEV']
      end
    end

    sys("sed -i -e 's,SpinLock,ISpinLock,g' src/*.cc src/*.h src/base/*.cc src/base/*.h")
    sys("git commit -am 'rename spinlock'") if ENV['DEV']
  end

  Dir.chdir(dir) do
    FileUtils.cp 'src/pprof', '../../../bin/'
    FileUtils.chmod 0755, '../../../bin/pprof'
  end

  Dir.chdir(dir) do
    if RUBY_PLATFORM =~ /darwin10/
      ENV['CFLAGS'] = ENV['CXXFLAGS'] = '-D_XOPEN_SOURCE'
    end
    sys("./configure --disable-heap-profiler --disable-heap-checker --disable-debugalloc --disable-shared")
    sys("make")
    FileUtils.cp '.libs/libprofiler.a', '../../librubyprofiler.a'
  end
end

$LIBPATH << CWD
$libs = append_library($libs, 'rubyprofiler')
def add_define(name)
  $defs.push("-D#{name}")
end

case RUBY_PLATFORM
when /darwin/, /linux/, /freebsd/
  CONFIG['LDSHARED'] = "$(CXX) " + CONFIG['LDSHARED'].split[1..-1].join(' ')
end

add_define 'RUBY18'

have_func('rb_during_gc', 'ruby.h')
create_makefile 'vm_perftools'
