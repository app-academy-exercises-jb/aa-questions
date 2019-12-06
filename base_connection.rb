require 'singleton'
require 'sqlite3'
require 'active_support/inflector'
require_relative 'base_model.rb'

class BaseDatabaseConnection
  def initialize(connection)
    raise "#{connection} not a valid file name" unless File.exist?(connection)
    
    db = BaseDatabaseConnection.connect(connection)

    #discover our tables to prep our object creation
    tables = []
    db.instance.execute("SELECT name FROM sqlite_master").each { |table|
      tables << table['name']
    }
    connection.instance_variable_set(:@db, db)
    connection.instance_variable_set(:@tables, tables)

    #now, define a new class for every table
    tables.each { |table|
      next if /^sqlite_/.match?(table) #we don't want sqlite internal tables

      # each new class gets a pointer back to the db connection
      # and a key with which to query it about itself
      klass = Object.const_set(table.capitalize.chomp('s'), Class.new {
        self.instance_variable_set(:@db, db)
        self.instance_variable_set(:@name, table)
        include BaseModel
      })

      params = klass.const_get(:PARAMS)

      params.each { |k,v|
        key = k.to_s
        method = ("find_by_" + key).to_sym
        klass.singleton_class.class_exec(db,key,table,method){ 
          # here we add a "find_by_x" method for every attribute
          define_method method do |val|
            data = db.instance.execute("SELECT * FROM #{table} WHERE #{key}='#{val}'")
            raise "#{key}: no results found for #{val}" unless !data.empty?
            data.map { |datum| self.new(datum) }
          end
        }
        # here we define a getter for every attribute
        klass.define_method key do
          self.instance_variable_get("@#{key}")
        end
        # and a setter
        klass.define_method (key+"=").to_sym do |val|
          self.instance_variable_set("@#{key}", val)
        end
        # we must redefine the #hash and #eql? methods of our custom classes, so that we can correctly do set operations on arrays of them later
        klass.define_method :hash do
          vars = {}
          self.instance_variables.each { |var| vars[var] = self.instance_variable_get(var) }
          vars.hash
        end
        klass.define_method :eql? do |obj|
          self.hash == obj.hash
        end

      }
    }
  end

  class << self
    def connect(connection)
      Class.new SQLite3::Database do
        include Singleton

        define_method :initialize do
          super connection
          self.type_translation = true
          self.results_as_hash = true
        end
      end
    end
  end
end