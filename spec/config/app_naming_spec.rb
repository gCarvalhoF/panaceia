require "rails_helper"

# Guards the "panaceia" naming (phase 9). The production names must match
# the homelab-iac role (POSTGRES_USER, PANACEIA_DATABASE_PASSWORD).
RSpec.describe "Application naming" do
  def database_config(env)
    ActiveRecord::Base.configurations.configs_for(env_name: env, include_hidden: true)
                      .to_h { |c| [ c.name, c.configuration_hash ] }
  end

  it "names the Rails application module Panaceia" do
    expect(Rails.application.class.module_parent_name).to eq("Panaceia")
  end

  it "uses panaceia-prefixed development and test databases" do
    expect(database_config("development")["primary"][:database]).to eq("panaceia_development")
    expect(database_config("test")["primary"][:database]).to eq("panaceia_test")
  end

  it "uses the panaceia user, password variable and databases in production" do
    yaml = ERB.new(Rails.root.join("config/database.yml").read)
    production = YAML.safe_load(yaml.result, aliases: true).fetch("production")

    expect(production.transform_values { |c| c["database"] }).to eq(
      "primary" => "panaceia_production",
      "cache" => "panaceia_production_cache",
      "queue" => "panaceia_production_queue",
      "cable" => "panaceia_production_cable"
    )
    expect(production["primary"]["username"]).to eq("panaceia")
    expect(Rails.root.join("config/database.yml").read).to include('ENV["PANACEIA_DATABASE_PASSWORD"]')
  end

  it "has no leftover references to the old project name" do
    patterns = %w[
      app/**/* config/**/* lib/**/* bin/* db/seeds.rb .github/**/*
      frontend/src/**/* frontend/index.html frontend/package.json frontend/package-lock.json
      Dockerfile Makefile docker-compose.yml README.md CLAUDE.md docs/PRD.md
    ]
    files = patterns.flat_map { |pattern| Dir.glob(Rails.root.join(pattern), File::FNM_DOTMATCH) }.select { |f| File.file?(f) }
    offenders = files.select { |f| File.binread(f).match?(/dados_acesso_saude_salvador|DadosAcessoSaudeSalvador/i) }

    expect(offenders).to be_empty
  end
end
