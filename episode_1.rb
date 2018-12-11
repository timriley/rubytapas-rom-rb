require "bundler/setup"
require "rom"
require "rom/sql"
require "time_math"

# Configure database URL

config = ROM::Configuration.new(:sql, "postgres://localhost/rubytapas_rom")
rom = ROM.container(config)

# Migrate database

rom.gateways[:default].tap do |gateway|
  migration = gateway.migration do
    change do
      drop_table? :articles
      drop_table? :authors

      create_table :authors do
        primary_key :id
        column :name, :text, null: false
      end

      create_table :articles do
        primary_key :id
        column :title, :text, null: false
        foreign_key :author_id, :authors
        column :published_at, :timestamp
      end
    end
  end

  migration.apply gateway.connection, :up

  # Populate data

  gateway.connection.tap do |connection|
    authors = [
      "Rebecca Sugar",
      "Kat Morris",
    ]

    titles = [
      ["Together breakfast", 1],
      ["Cat fingers", 2],
    ]

    now = Time.now

    authors.each do |author|
      connection.execute("INSERT INTO authors (name) VALUES ('#{author}')")
    end

    titles.each_with_index do |title, i|
      published_at = TimeMath(now).floor(:day).decrease(:day, titles.length - i).().strftime('%Y-%m-%d 00:00:00')
      author_id = title[1]

      connection.execute <<~SQL
        INSERT INTO articles (title, published_at, author_id)
        VALUES ('#{title[0]}', '#{published_at}', #{author_id})
      SQL
    end
  end
end

# Define relations

module Relations
  class Articles < ROM::Relation[:sql]
    schema :articles, infer: true do
      associations do
        belongs_to :author
      end
    end

    def ordered_by_recency
      order { published_at.desc }
    end
  end

  class Authors < ROM::Relation[:sql]
    schema :authors, infer: true
  end
end

# Register relations and finalize rom container

config.register_relation Relations::Articles
config.register_relation Relations::Authors

rom = ROM.container(config)

# Define entities/repositories

module Entities
  class Article < ROM::Struct
    def display_title
      [published_at.strftime('%b %d'), title].join(" - ")
    end
  end
end

class ArticleRepo < ROM::Repository
  struct_namespace Entities

  def latest
    articles
      .combine(:author)
      .ordered_by_recency
      .to_a
  end
end

# Instantiate repository and inspect output

repo = ArticleRepo.new(rom)
repo.latest
