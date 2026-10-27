require 'test_helper'
require 'tmpdir'
require 'open3'

class SharedAssetsRakeTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  def setup
    @directory = Dir.mktmpdir('shared-assets')
    @project = File.join(@directory, 'app')
    @source = File.join(@directory, 'source')
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
    File.write(File.join(@project, 'Gemfile'), "source 'https://rubygems.org'\ngem 'rake'\n")
    File.write(File.join(@project, 'Rakefile'), "load 'lib/tasks/ecosystems.rake'\n")
    File.write(File.join(@project, 'bin/rails'), "#!/bin/sh\nexit 0\n")
    File.chmod(0o755, File.join(@project, 'bin/rails'))
    %w[config/application.rb config/environment.rb].each do |path|
      File.write(File.join(@project, path), '')
    end

    @env = Bundler.unbundled_env.merge(
      'BUNDLE_GEMFILE' => File.join(@project, 'Gemfile'),
      'GIT_CONFIG_COUNT' => '4',
      'GIT_CONFIG_KEY_0' => 'core.hooksPath',
      'GIT_CONFIG_VALUE_0' => '/dev/null',
      'GIT_CONFIG_KEY_1' => 'commit.gpgsign',
      'GIT_CONFIG_VALUE_1' => 'false',
      'GIT_CONFIG_KEY_2' => "url.file://#{@source}.insteadOf",
      'GIT_CONFIG_VALUE_2' => 'https://github.com/ecosyste-ms/documentation',
      'GIT_CONFIG_KEY_3' => 'protocol.file.allow',
      'GIT_CONFIG_VALUE_3' => 'always'
    )
    command(@project, RbConfig.ruby, Gem.bin_path('bundler', 'bundle'), 'lock', '--local')
    [@source, @project].each do |root|
      command(root, 'git', 'init', '-q', '-b', 'main')
      command(root, 'git', 'config', 'user.name', 'Shared assets test')
      command(root, 'git', 'config', 'user.email', 'test@example.invalid')
      commit_fixture(root)
    end
    @head = command(@project, 'git', 'rev-parse', 'HEAD')
    @dependencies = %w[Gemfile Gemfile.lock].to_h { |file| [file, File.binread(File.join(@project, file))] }
  end

  def teardown
    if @dependencies
      @dependencies.each { |file, content| assert_equal content, File.binread(File.join(@project, file)) }
      assert_equal @head, command(@project, 'git', 'rev-parse', 'HEAD')
      assert_empty command(@project, 'git', 'diff', '--cached', '--name-only')
    end
    FileUtils.remove_entry(@directory)
  end

  def command(directory, *arguments)
    output, error, status = Open3.capture3(@env, *arguments, chdir: directory, unsetenv_others: true)
    assert status.success?, "#{arguments.join(' ')}: #{output}\n#{error}"
    output
  end

  def commit_fixture(directory)
    command(directory, 'git', 'add', '.')
    command(directory, 'git', 'commit', '-qm', 'Fixture')
  end

  def update_assets
    Open3.capture3(@env, RbConfig.ruby, Gem.bin_path('bundler', 'bundle'), 'exec', 'rake', 'ecosystems:update_shared_assets', chdir: @project, unsetenv_others: true)
  end

  def assert_migrated(header)
    output, error, status = update_assets
    assert status.success?, "#{output}\n#{error}"
    result = File.read(File.join(@project, @header_path))
    before, after = header.split(/      <div id="header__global__menu".*?^      <\/div>\n/m, 2)
    assert_equal "#{before}      <%= render 'shared/services_menu' %>\n#{after}", result
    assert_equal @partial, File.read(File.join(@project, @partial_path))
    assert_equal 'local navigation', File.read(File.join(@project, 'app/views/shared/_menu.html.erb'))
  end

  test 'updates assets and extracts the home menu without changing local navigation' do
    assert_migrated(@header)
  end

  test 'preserves the application layout when refreshing assets and the rake task' do
    layout_path = File.join(@project, 'app/views/layouts/application.html.erb')
    layout = "<head><%= auto_discovery_link_tag(:atom, global_feed_path) %></head><body><%= yield %></body>"
    File.write(layout_path, layout)
    File.open(File.join(@project, @task_path), 'a') { |file| file.puts "\n" }

    assert_migrated(@header)

    assert_equal layout, File.read(layout_path)
  end

  test 'installs the shared application layout when none exists' do
    assert_migrated(@header)

    assert_equal File.read(File.join(@source, 'app/views/layouts/application.html.erb')),
      File.read(File.join(@project, 'app/views/layouts/application.html.erb'))
  end

  test 'preserves app-specific crawler rules while refreshing public assets' do
    robots_path = File.join(@project, 'public/robots.txt')
    rules = "User-agent: *\nAllow: /\nDisallow: /*?*previous_month=\nDisallow: /*?*previous_year=\n"
    File.write(robots_path, rules)
    File.write(File.join(@source, 'public/favicon.ico'), 'new favicon')
    commit_fixture(@source)

    assert_migrated(@header)

    assert_equal rules, File.read(robots_path)
    assert_equal 'new favicon', File.read(File.join(@project, 'public/favicon.ico'))
  end

  test 'installs crawler rules when none exist' do
    assert_migrated(@header)

    assert_equal File.read(File.join(@source, 'public/robots.txt')),
      File.read(File.join(@project, 'public/robots.txt'))
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
    commit_fixture(@source)

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
    refute File.exist?(File.join(@project, 'tmp/ecosystems_assets'))
  end

  test 'rejects duplicate menus' do
    File.write(File.join(@project, @header_path), @header + @header)

    _, error, status = update_assets

    refute status.success?
    assert_includes error, 'Unrecognized services menu'
    assert_equal @header + @header, File.read(File.join(@project, @header_path))
    refute File.exist?(File.join(@project, 'tmp/ecosystems_assets'))
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
    refute File.exist?(File.join(@project, 'tmp/ecosystems_assets'))
  end

  test 'stops when cloning fails without reporting success or changing assets' do
    @env['GIT_CONFIG_KEY_2'] = "url.file://#{@directory}/missing.insteadOf"

    output, _, status = update_assets

    refute status.success?
    refute_includes output, 'Shared assets updated'
    assert_equal @header, File.read(File.join(@project, @header_path))
    refute File.exist?(File.join(@project, @partial_path))
    refute File.exist?(File.join(@project, 'tmp/ecosystems_assets'))
  end

  test 'rejects missing source assets before changing the header' do
    File.delete(File.join(@source, 'app/views/shared/_footer.html.erb'))
    commit_fixture(@source)

    output, error, status = update_assets

    refute status.success?
    assert_includes error, 'Missing shared asset: app/views/shared/_footer.html.erb'
    refute_includes output, 'Shared assets updated'
    assert_equal @header, File.read(File.join(@project, @header_path))
    refute File.exist?(File.join(@project, @partial_path))
    refute File.exist?(File.join(@project, 'tmp/ecosystems_assets'))
  end

  test 'reports a copy failure and cleans up the clone' do
    File.symlink('missing/stylesheet', File.join(@project, 'app/assets/stylesheets/ecosystems.scss'))

    output, error, status = update_assets

    refute status.success?
    assert_includes error, 'ecosystems.scss'
    refute_includes output, 'Shared assets updated'
    refute File.exist?(File.join(@project, 'tmp/ecosystems_assets'))
  end
end
