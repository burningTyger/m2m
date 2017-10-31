require 'active_model/serializers'
require "sequel"
require "sqlite3"
require "mongo_mapper"
require "babosa"
# require "pry"


  MongoMapper.connection = Mongo::Connection.new("localhost")
  MongoMapper.database = "farhang"

  class LemmaN
    include MongoMapper::Document
    set_collection_name "lemmas"
  end

  DB=Sequel.sqlite('farhang.db')
  Sequel::Model.strict_param_setting = false

class Lemma < Sequel::Model
  one_to_many :translations
  def before_create
    super
    self.lemma.strip!
    set_slug!
  end

  def before_update
    super
    set_slug if modified?(:lemma)
  end

  def before_destroy
    super
    self.remove_all_translations
  end

  def set_slug!
    self.slug = lemma.to_slug.clean.normalize(:transliterate => :german).to_s
    if l = Lemma.find(:slug => self.slug)
      nr = (l.lemma.split("").last.to_i)+1
      self.slug = self.slug+"_"+nr.to_s
      p self
    end
  end
end

class Translation < Sequel::Model
  def before_create
    super
    self.source.strip!
    self.target.strip!
  end
end

# binding.pry
LemmaN.all.each_with_index do |l,i|
  lemma = Lemma.create(:lemma => l.lemma)
  l.translations.each do |t|
    translation = Translation.create(:source => t["source"], :target => t["target"])
    lemma.add_translation(translation)
  end
  puts i if i%100==0
end
