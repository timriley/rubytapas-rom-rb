require "bundler/setup"
require "rom"
require "rom/sql"

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
        column :slug, :text, null: false
        foreign_key :author_id, :authors
        column :published_at, :timestamp
      end
    end
  end

  migration.apply gateway.connection, :up
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

# Define entities/changesets/repositories

module Entities
end

class CreateArticle < ROM::Changeset::Create
  map do |tuple|
    tuple.merge(
      slug: tuple[:title].downcase.gsub(/\s/, "-"),
    )
  end
end

class ArticleRepo < ROM::Repository
  struct_namespace Entities

  def create(attrs)
    transaction do
      author = authors.changeset(:create, attrs[:author]).commit

      articles.changeset(CreateArticle, attrs).associate(author).commit
    end
  end

  def update(id, attrs)
    articles.by_pk(id).changeset(:update, attrs).commit
  end

  def latest
    articles
      .combine(:author)
      .ordered_by_recency
      .to_a
  end
end

# Instantiate repository and inspect output

repo = ArticleRepo.new(rom)

article = repo.create(
  title: "Together breakfast",
  published_at: Time.now,
  author: {name: "Rebecca Sugar"},
)

repo.latest
