require 'test_helper'
require 'tmpdir'
require 'open3'

class SharedAssetsRakeTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  def setup
    @directory = Dir.mktmpdir('shared-assets')
    @project = File.join(@directory, 'app')
    @source = File.join(@directory, 'source')
    @commands = File.join(@directory, 'commands')
    @header_path = 'app/views/shared/_header.html.erb'
    @partial_path = 'app/views/shared/_services_menu.html.erb'
    @task_path = 'lib/tasks/ecosystems.rake'
    @header = Rails.root.join('test/fixtures/files/shared_headers/home.html.erb').read
    @partial = Rails.root.join(@partial_path).read

    [@project, @source].each do |root|
      %w[bin config lib/tasks app/views/shared app/views/layouts app/assets/stylesheets app/assets/images app/helpers public].each do |path|
        FileUtils.mkdir_p(File.join(root, path))
      end
      FileUtils.cp(Rails.root.join(@task_path), File.join(root, @task_path))
    end
    File.write(File.join(@source, @header_path), Rails.root.join(@header_path).read)
    File.write(File.join(@source, @partial_path), @partial)
    %w[app/views/shared/_footer.html.erb app/views/shared/_menu.html.erb app/views/layouts/application.html.erb app/assets/stylesheets/ecosystems.scss app/helpers/ecosystems_helper.rb app/assets/images/test.svg public/robots.txt].each do |path|
      File.write(File.join(@source, path), "shared #{path}\n")
    end
    File.write(File.join(@project, @header_path), @header)
    File.write(File.join(@project, 'app/views/shared/_menu.html.erb'), 'local navigation')
    File.write(File.join(@project, 'Gemfile'), "source 'https://rubygems.org'\n")
    File.write(File.join(@project, 'Rakefile'), "load 'lib/tasks/ecosystems.rake'\n")
    File.write(File.join(@project, 'bin/rails'), "#!/bin/sh\nexit 0\n")
    File.chmod(0o755, File.join(@project, 'bin/rails'))
    %w[config/application.rb config/environment.rb].each do |path|
      File.write(File.join(@project, path), '')
    end

    mocks = File.join(@directory, 'mocks')
    FileUtils.mkdir_p(mocks)
    real_git, status = Open3.capture2('which', 'git')
    assert status.success?
    File.write(File.join(mocks, 'git'), <<~'SH')
      #!/bin/bash
      if [ "$1" = clone ]; then
        cp -R "$SHARED_ASSETS_SOURCE/." "${@: -1}"
      elif [ "$1" = commit ]; then
        printf 'commit\n' >> "$SHARED_ASSETS_COMMANDS"
      else
        exec "$SHARED_ASSETS_GIT" "$@"
      fi
    SH
    File.write(File.join(mocks, 'bundle'), <<~'SH')
      #!/bin/sh
      printf 'bundle %s\n' "$*" >> "$SHARED_ASSETS_COMMANDS"
    SH
    File.chmod(0o755, File.join(mocks, 'git'), File.join(mocks, 'bundle'))
    @env = {
      'PATH' => "#{mocks}:#{ENV.fetch('PATH')}",
      'SHARED_ASSETS_SOURCE' => @source,
      'SHARED_ASSETS_COMMANDS' => @commands,
      'SHARED_ASSETS_GIT' => real_git.strip
    }
    _, error, status = Open3.capture3(real_git.strip, 'init', '-q', @project)
    assert status.success?, error
  end

  def teardown
    FileUtils.remove_entry(@directory)
  end

  def update_assets
    Open3.capture3(@env, RbConfig.ruby, Gem.bin_path('rake', 'rake'), 'ecosystems:update_shared_assets', chdir: @project)
  end

  def assert_migrated(header)
    output, error, status = update_assets
    assert status.success?, "#{output}\n#{error}"
    result = File.read(File.join(@project, @header_path))
    before, after = header.split(/      <div id="header__global__menu".*?^      <\/div>\n/m, 2)
    assert_equal "#{before}      <%= render 'shared/services_menu' %>\n#{after}", result
    assert_equal @partial, File.read(File.join(@project, @partial_path))
    assert_equal 'local navigation', File.read(File.join(@project, 'app/views/shared/_menu.html.erb'))
    staged, = Open3.capture2('git', 'diff', '--cached', '--name-only', chdir: @project)
    assert_includes staged.lines.map(&:strip), @partial_path
    assert_includes staged.lines.map(&:strip), @header_path
  end

  test 'updates assets and extracts the home menu without changing local navigation' do
    assert_migrated(@header)
  end

  test 'extracts the packages menu' do
    header = Rails.root.join('test/fixtures/files/shared_headers/packages.html.erb').read
    File.write(File.join(@project, @header_path), header)
    assert_migrated(header)
  end

  test 'extracts the original menu with whitespace inside links' do
    header = @header.sub('><%= service[:name] %></a>', ">\n                    <%= service[:name] %>\n                  </a>")
    File.write(File.join(@project, @header_path), header)
    assert_migrated(header)
  end

  test 'refreshes an extracted menu without rewriting the header' do
    output, error, status = update_assets
    assert status.success?, "#{output}\n#{error}"
    header = File.read(File.join(@project, @header_path))
    File.write(File.join(@source, @partial_path), 'updated shared menu')

    output, error, status = update_assets

    assert status.success?, "#{output}\n#{error}"
    assert_equal header, File.read(File.join(@project, @header_path))
    assert_equal 'updated shared menu', File.read(File.join(@project, @partial_path))
  end

  test 'rejects a custom menu before changing the header or other assets' do
    header = @header.sub('<%= service[:name] %>', 'Custom service name')
    File.write(File.join(@project, @header_path), header)

    _, error, status = update_assets

    refute status.success?
    assert_includes error, 'Unrecognized services menu'
    assert_equal header, File.read(File.join(@project, @header_path))
    refute File.exist?(File.join(@project, @partial_path))
    refute File.exist?(File.join(@project, 'app/views/shared/_footer.html.erb'))
    refute File.exist?(@commands)
  end

  test 'rejects duplicate menus' do
    File.write(File.join(@project, @header_path), @header + @header)

    _, error, status = update_assets

    refute status.success?
    assert_includes error, 'Unrecognized services menu'
    assert_equal @header + @header, File.read(File.join(@project, @header_path))
    refute File.exist?(@commands)
  end

  test 'loads the new menu migration after refreshing its rake task' do
    File.open(File.join(@project, @task_path), 'a') { |file| file.puts "\n" }
    assert_migrated(@header)
    assert_equal Rails.root.join(@task_path).read, File.read(File.join(@project, @task_path))
  end

  test 'installs the partial alongside a missing header' do
    File.delete(File.join(@project, @header_path))

    output, error, status = update_assets

    assert status.success?, "#{output}\n#{error}"
    assert_equal Rails.root.join(@header_path).read, File.read(File.join(@project, @header_path))
    assert_equal @partial, File.read(File.join(@project, @partial_path))
  end

  test 'refuses a converted app with leftover ruby files' do
    File.delete(File.join(@project, 'config/application.rb'))
    File.write(File.join(@project, 'go.mod'), "module example.com/service\n")

    _, error, status = update_assets

    refute status.success?
    assert_includes error, 'Shared assets can only be updated in a Rails app'
    assert_equal @header, File.read(File.join(@project, @header_path))
    refute File.exist?(@commands)
    refute File.exist?(File.join(@project, 'tmp/ecosystems_assets'))
  end
end
