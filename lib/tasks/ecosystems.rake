namespace :ecosystems do
  task :update_shared_assets do
    unless File.executable?('bin/rails') && %w[Gemfile config/application.rb config/environment.rb].all? { |path| File.file?(path) }
      raise 'Shared assets can only be updated in a Rails app'
    end

    shared_asset_repo = "https://github.com/ecosyste-ms/documentation"
    branch = "main"
    temp_dir = "tmp/ecosystems_assets"
    ecosystems_rake_path = "lib/tasks/ecosystems.rake"
    temp_rake_file = "#{temp_dir}/lib/tasks/ecosystems.rake"

    # Ensure temp directory is clean
    `rm -rf #{temp_dir}`
    `mkdir -p #{temp_dir}`

    # Clone the repo with only the required branch
    `git clone --depth=1 --branch #{branch} #{shared_asset_repo} #{temp_dir}`

    # Ensure target directories exist
    `mkdir -p app/views/shared`
    `mkdir -p app/assets/stylesheets`
    `mkdir -p app/helpers`
    `mkdir -p app/assets/images`
    `mkdir -p public`

    # Check if ecosystems.rake has changed
    if !FileUtils.compare_file(temp_rake_file, ecosystems_rake_path)
      puts "ecosystems.rake has changed, restarting task with new code..."
      `cp #{temp_rake_file} #{ecosystems_rake_path}`

      # Cleanup
      `rm -rf #{temp_dir}`

      # Re-execute the current Rake task using exec to replace the running process
      exec("rake ecosystems:update_shared_assets")
    end

    header_file = "app/views/shared/_header.html.erb"
    FileUtils.cp("#{temp_dir}/#{header_file}", header_file) unless File.exist?(header_file)
    Rake::Task['ecosystems:update_services_menu'].invoke(temp_dir)

    # Install required gems
    `bundle add bootstrap-icons-helper`

    # Copy required files
    `cp #{temp_rake_file} #{ecosystems_rake_path}`
    `cp #{temp_dir}/app/views/shared/_footer.html.erb app/views/shared/`
    `cp #{temp_dir}/app/views/layouts/application.html.erb app/views/layouts/`
    `cp #{temp_dir}/app/assets/stylesheets/ecosystems.scss app/assets/stylesheets/`
    `cp #{temp_dir}/app/helpers/ecosystems_helper.rb app/helpers/`
    `cp -r #{temp_dir}/app/assets/images/. app/assets/images/`
    `cp -r #{temp_dir}/public/. public/`

    # Copy _menu.html.erb only if it does not already exist
    menu_file = "app/views/shared/_menu.html.erb"
    unless File.exist?(menu_file)
      `cp #{temp_dir}/app/views/shared/_menu.html.erb #{menu_file}`
    end

    # Cleanup
    `rm -rf #{temp_dir}`

    # git add and commit
    `git add lib/tasks/ecosystems.rake app/views/shared/_header.html.erb app/views/shared/_services_menu.html.erb app/views/shared/_footer.html.erb app/views/shared/_menu.html.erb app/views/layouts/application.html.erb app/assets/stylesheets/ecosystems.scss app/helpers/ecosystems_helper.rb app/assets/images/ public/`
    `git commit -m "Update shared assets from #{shared_asset_repo}"`

    puts "Shared assets updated successfully."
  end

  task :update_services_menu, [:source] do |_, args|
    header_file = 'app/views/shared/_header.html.erb'
    partial_file = 'app/views/shared/_services_menu.html.erb'
    partial = File.read(File.join(args[:source], partial_file))
    header = File.read(header_file)
    render_call = "<%= render 'shared/services_menu' %>"

    # Keep the migration independent of future edits to the shared partial.
    legacy_menu = <<~'ERB'.lines.map { |line| "      #{line}" }.join
      <div id="header__global__menu" class="collapse header__global__menu">
        <% ecosystems_services.each do |category, services| %>
          <div class="header__global__menu__category">
            <h2 class="header__global__menu__category-title"><%= category %></h2>
            <ul class="header__global__menu__category-links">
              <% services.each do |service| %>
                <li>
                  <a href="<%= service[:url] %>" target="_blank" class="<%= 'active' if service[:url] == request.base_url %>"><%= service[:name] %></a>
                </li>
              <% end %>
            </ul>
          </div>
        <% end %>
      </div>
    ERB
    variants = [
      legacy_menu,
      legacy_menu.sub('><%= service[:name] %></a>', ">\n                    <%= service[:name] %>\n                  </a>"),
      legacy_menu.sub('><%= service[:name] %></a>', "\n                    ><%= service[:name] %></a\n                  >")
    ]
    menu_count = header.scan('id="header__global__menu"').length
    render_count = header.scan(render_call).length

    unless render_count == 1 && menu_count.zero?
      matches = variants.select { |menu| header.include?(menu) }
      unless render_count.zero? && menu_count == 1 && matches.one?
        raise "Unrecognized services menu in #{header_file}; inspect it before updating shared assets"
      end
      header = header.sub(matches.first, "      #{render_call}\n")
    end

    File.write(partial_file, partial)
    File.write(header_file, header)
  end

  task :setup_shared_assets, [:target_repo] do |_t, args|
    target_repo_path = "../#{args[:target_repo]}"
    puts "Setting up shared assets for repository at: #{target_repo_path}"

    # Ensure target directory exists
    `mkdir -p #{target_repo_path}/lib/tasks`

    # Copy required files
    `cp lib/tasks/ecosystems.rake #{target_repo_path}/lib/tasks/`

    puts "Shared assets setup completed successfully."

    # add app_name and app_description to the target repo
    puts "Add the following to app/helpers/application_helper.rb in the target repo:"
    puts "module ApplicationHelper"
    puts "  def app_name"
    puts "    \"AppName\""
    puts "  end"
    puts ""
    puts "  def app_description"
    puts "    \"Description of the app.\""
    puts "  end"
    puts "end"
  end
end
