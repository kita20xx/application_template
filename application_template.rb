#
# Application Template
#

# global
@application_name = app_name

#
# Gemfileにgemを追加
#
gem_group :test, :development do
  # テストにはrspec, factory_girlを使用します
  gem 'rspec-rails'
  gem 'factory_girl_rails'
end

gem_group :development do
  # railsコマンドの高速化
  gem 'spring-commands-rspec'
end

# Bootstrap3を使用します
#
# masterはBootstrap2なのでbranchを指定
gem 'less-rails'
gem 'twitter-bootstrap-rails', git: 'https://github.com/seyhunak/twitter-bootstrap-rails.git', branch: 'bootstrap3'

# Gemfileの指定行をコメント
comment_lines "Gemfile", "gem 'sqlite3'"
# Gemfileの指定行のコメントを外す
uncomment_lines "Gemfile", "gem 'therubyracer'"

#
# Bundle install
#
run_bundle

#
# Files and Directories
#
# RSpec使うのでtestディレクトリは不要
remove_dir "test"
# index.htmlは不要
remove_file "public/index.html"
# application.html.erbはBootstrapでgenerateするので消しておく
remove_file "app/views/layouts/application.html.erb"

# generate時にrspecを自動生成するように修正
application <<-APPEND_APPLICATION
config.generators do |generate|
      generate.test_framework   :rspec, fixture: true, views: false
      generate.integration_tool :rspec, fixture: true, views: true
    end
APPEND_APPLICATION

# assetsがうるさいので黙らせる
initializer "quiet_assets.rb", <<-CODE
Rails.application.assets.logger = Logger.new(File::NULL)
Rails::Rack::Logger.class_eval do
  def call_with_quiet_assets(env)
    previous_level = Rails.logger.level
    Rails.logger.level = Logger::ERROR if env['PATH_INFO'].index("/assets/") == 0
    call_without_quiet_assets(env).tap do
      Rails.logger.level = previous_level
    end
  end
  alias_method_chain :call, :quiet_assets
end
CODE

#
# Generators
#

# database
gsub_file "config/database.yml", /password:$/, %(password: root)
rake "db:create", env: "development"
rake "db:create", env: "test"
rake "db:migrate"
rake "test:prepare"

# rspec
run "bundle binstubs rspec-core"
generate "rspec:install"
comment_lines "spec/spec_helper.rb", "require 'rspec/autorun'"

# spring
run "spring binstub rspec"

# factory girl
run "mkdir -p spec/factories"

# bootstrap3
generate "bootstrap:install"
generate "bootstrap:layout application fluid"
gsub_file "app/views/layouts/application.html.erb", /lang="en"/, %(lang="ja")

# dashboard
generate :controller, "dashboard", "show"
route "root to: 'dashboard#show'"

#
# Git
#
git :init
git add: "."
git commit: "-am 'Initial commit'"
