require 'rubygems/test_case'
require 'rubygems/installer'

class Gem::Installer

  ##
  # Available through requiring rubygems/installer_test_case

  attr_accessor :gem_dir

  ##
  # Available through requiring rubygems/installer_test_case

  attr_writer :format

  ##
  # Available through requiring rubygems/installer_test_case

  attr_writer :gem_home

  ##
  # Available through requiring rubygems/installer_test_case

  attr_writer :env_shebang

  ##
  # Available through requiring rubygems/installer_test_case

  attr_writer :ignore_dependencies

  ##
  # Available through requiring rubygems/installer_test_case

  attr_writer :format_executable

  ##
  # Available through requiring rubygems/installer_test_case

  attr_writer :security_policy

  ##
  # Available through requiring rubygems/installer_test_case

  attr_writer :spec

  ##
  # Available through requiring rubygems/installer_test_case

  attr_writer :wrappers
end

##
# A test case for Gem::Installer.

class Gem::InstallerTestCase < Gem::TestCase

  def setup
    super

    @spec = quick_gem 'a'
    util_make_exec @spec

    @gem = File.join @tempdir, @spec.file_name

    @installer = util_installer @spec, @gem, @gemhome

    @user_spec = quick_gem 'b'
    util_make_exec @user_spec

    @user_gem = File.join @tempdir, @user_spec.file_name

    @user_installer = util_installer @user_spec, @user_gem, Gem.user_dir
    @user_installer.gem_dir = Gem.user_dir.gems.add(@user_spec.full_name)
  end

  def util_gem_bindir spec = @spec
    util_gem_dir(spec).add("bin")
  end

  def util_gem_dir spec = @spec
    @gemhome.gems.add(spec.full_name)
  end

  def util_inst_bindir
    @gemhome.bin
  end

  def util_make_exec(spec = @spec, shebang = "#!/usr/bin/ruby")
    spec.executables = %w[executable]
    spec.files << 'bin/executable'

    bindir = util_gem_bindir spec
    FileUtils.mkdir_p bindir
    exec_path = bindir.add('executable')
    open exec_path, 'w' do |io|
      io.puts shebang
    end

    temp_bin = Gem::Path.new(@tempdir).add('bin')
    FileUtils.mkdir_p temp_bin
    open temp_bin.add('executable'), 'w' do |io|
      io.puts shebang
    end
  end

  def util_setup_gem(ui = @ui) # HACK fix use_ui to make this automatic
    @spec.files << File.join('lib', 'code.rb')
    @spec.extensions << File.join('ext', 'a', 'mkrf_conf.rb')

    Dir.chdir @tempdir do
      FileUtils.mkdir_p 'bin'
      FileUtils.mkdir_p 'lib'
      FileUtils.mkdir_p File.join('ext', 'a')
      File.open File.join('bin', 'executable'), 'w' do |f| f.puts '1' end
      File.open File.join('lib', 'code.rb'), 'w' do |f| f.puts '1' end
      File.open File.join('ext', 'a', 'mkrf_conf.rb'), 'w' do |f|
        f << <<-EOF
          File.open 'Rakefile', 'w' do |rf| rf.puts "task :default" end
        EOF
      end

      use_ui ui do
        FileUtils.rm @gem
        Gem::Builder.new(@spec).build
      end
    end

    @installer = Gem::Installer.new Gem::FS.new @gem
  end

  def util_installer(spec, gem_path, gem_home)
    util_build_gem spec
    FileUtils.mv Gem.cache_gem(spec.file_name), @tempdir
    installer = Gem::Installer.new Gem::FS.new gem_path
    installer.gem_dir = util_gem_dir
    installer.gem_home = Gem::FS.new gem_home
    installer.spec = spec

    installer
  end

end

