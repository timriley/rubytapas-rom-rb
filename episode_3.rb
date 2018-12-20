require "bundler/setup"
require "rom"
require "rom/sql"
require "time_math"

# Configure database URL

config = ROM::Configuration.new(:sql, "postgres://localhost/ruby_tapas_rom")
rom = ROM.container(config)

# Migrate database

rom.gateways[:default].tap do |gateway|
  migration = gateway.migration do
    change do
      drop_table? :articles
      drop_table? :authors
      drop_table? :comments

      create_table :authors do
        primary_key :id
        column :name, :text, null: false
      end

      create_table :articles do
        primary_key :id
        column :title, :text, null: false
        column :subtitle, :text
        column :slug, :text, null: false
        column :body, :text, null: false
        foreign_key :author_id, :authors
        column :published_at, :timestamp
      end

      create_table :comments do
        primary_key :id
        foreign_key :article_id, null: false
        column :name, :text, null: false
        column :body, :text, null: false
        column :created_at, :timestamp, null: false
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
      ["Together breakfast", "I made you to bring us together!", 1],
      ["Cat fingers", "Biorhythms, yo", 2],
    ]

    comments = [
      ["Garnet", "I have to burn this too."],
      ["Steven", "Noo, my apps!"],
      ["Pearl", "Care to explain this sword?"],
      ["Amythest", "Alright, snacks!"],
    ]

    authors.each do |author|
      connection.execute("INSERT INTO authors (name) VALUES ('#{author}')")
    end

    now = Time.now
    lorem = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."

    titles.each_with_index do |title, i|
      published_at = TimeMath(now).floor(:day).decrease(:day, titles.length - i).().strftime('%Y-%m-%d 00:00:00')
      author_id = title[2]

      connection.execute <<~SQL
        INSERT INTO articles (title, subtitle, slug, body, published_at, author_id)
        VALUES ('#{title[0]}', '#{title[1]}', '#{title[0].downcase.gsub(/\s/, "-")}', '#{lorem}', '#{published_at}', #{author_id})
      SQL
    end

    comments.each_with_index do |comment, i|
      created_at = TimeMath(now).floor(:day).decrease(:day, comments.length - i).().strftime('%Y-%m-%d 00:00:00')

      connection.execute <<~SQL
        INSERT INTO comments (article_id, name, body, created_at)
        VALUES (1, '#{comment[0]}', '#{comment[1]}', '#{created_at}')
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
        has_many :comments, view: :ordered
      end
    end
  end

  class Authors < ROM::Relation[:sql]
    schema :authors, infer: true
  end

  class Comments < ROM::Relation[:sql]
    schema :comments, infer: true

    def ordered
      order { created_at.desc }
    end
  end
end

# Register relations and finalize rom container

config.register_relation Relations::Articles
config.register_relation Relations::Authors
config.register_relation Relations::Comments

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
      .select { [id, title] }
      .combine(:comments)
      .to_a
  end
end

# Instantiate repository and inspect output

repo = ArticleRepo.new(rom)
repo.latest
