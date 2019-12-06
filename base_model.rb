# gotta write specs for all this 
# this module must manage a connection to a specfic sqlite db
# a class of this module must represent a given table

# we must implement:
# save
##all
# find_by(*attribs)
# find_by_attrib for every attrib**find_many by attrib
##where(query) **query table directly
# find_by_pk


require 'byebug'
require 'singleton'
require 'sqlite3'
require 'active_support/inflector'

module BaseModel
  def self.included(child)
    child.define_method :initialize do |opt_hash|
      if (opt_hash.class == Array && !opt_hash.empty?)
        opt_hash.each { |hash|
          self.class.new(hash)
        }
      elsif (opt_hash.class == SQLite3::ResultSet::HashWithTypesAndFields ||
          opt_hash.class == hash)
        parsed = self.class.opt_parser(opt_hash)
        self.class.object_validator(parsed)
        parsed.each { |k,v| self.instance_variable_set("@#{k}", v) }
      else
        raise "fatal: only SQLite3 hashes and arrays of hashes allowed"
      end

    end

    child.extend ClassMethods
  end

  module ClassMethods
    def self.extended(child)
      db = child.instance_variable_get(:@db)
      name = child.instance_variable_get(:@name)

      #sql injection attack vector
      table_info = db.instance.execute("PRAGMA table_info(#{name})") 

      params = {}
    
      table_info.each { |hash|
        params[hash["name"].to_sym] = {
          name: hash["name"],
          type: hash["type"],
          nullable: (hash["notnull"] != 1),
          dflt_val: hash["dflt_value"],
          primary: (hash["pk"] == 1)
        }
      }
      child.const_set("PARAMS", params)
    end

    def opt_parser(opt_hash)
      opt_hash.map { |k,v|
        [k.to_sym, v]
      }.to_h
    end

    def object_validator(opt_hash)
      # params = self.class_variable_get(:@@params)
      params = self.const_get("PARAMS")

      nullables = params.values.select { |h| h[:nullable] == true}

      if !opt_hash.has_key?(:id) #this should instead check if the hash has a pk
        raise "wrong number of params" unless opt_hash.length <= params.length - nullables.length
        #we assume right now that the pk is an id which is nullable in the schema
      else
        raise "wrong num of params" unless opt_hash.length == params.values.length
      end

      params.each { |k,v|
        if !opt_hash.has_key?(k) && v[:nullable] == false
          raise "#{k} must be a parameter of #{@name}"
        end
      }

      attrib_validator(opt_hash)

      true
    end

    def attrib_validator(opt_hash)
      params = self.const_get("PARAMS")

      opt_hash.each { |k,v|
        unless params.has_key?(k) # evidently this is not safe, as @@params can be written all willy nilly. must wrap in a getter of some sort. frozen? the real problem is that the params can't be in an individual object's instance vars
          raise "#{k} is not a valid column of the table #{@name}"
        else
          unless v.class <= object_type(params[k][:type])
            unless v.nil? || params[k][:nullable]
              raise "#{v} is not of valid type: #{params[k][:type]}"
            end
          end
        end
      }
    end

    def object_type(type)
      # a lot more parsing work is necessary here, given that sqlite3 stores all sorts of
      # numbers in TEXT
      case type
      when 'TEXT'
        String
      when 'NUMERIC'
        Numeric
      when 'INTEGER'
        Integer
      when 'REAL'
        Float
      when 'BLOB'
        rasise "pls implement me for type BLOB"
      else
        raise "unknown data type"
      end
    end

    # query methods
    def all
      data = @db.instance.execute("SELECT * FROM #{@name}")
      data.map { |datum| self.new(datum) }
    end

    def find_by(attribs)
      raise "expecting a hash" unless attribs.is_a?(Hash)
      
      attribs.each { |attrib| attrib_validator([attrib].to_h) }

      results = []

      attribs.each { |attrib|
        begin
          finder = "find_by_#{attrib[0].to_s}".to_sym
          results << self.send(finder, attrib[1])
        rescue
          next
        end
      }
      
      results.reduce(:&)
    end

    def where(query)
      # sql injection attack vector
      # i wonder how ActiveRecord sanitizes..
      data = @db.instance.execute("SELECT * FROM #{@name} WHERE #{query}")
      self.new(data)
    end

    def query(qur_a, qur_b)
      # sql injection attack vector
      @db.instance.execute("SELECT #{qur_a} FROM #{@name} #{qur_b}")
    end
  end

  # instance methods
  def save
    db = self.class.instance_variable_get(:@db)

    if self.id.nil? #new entry
      columns = instance_variables.map { |var| var.to_s[1..-1] }
      values = instance_variables.map { |var| instance_variable_get(var) }

      db.instance.execute(<<-SQL)
        INSERT INTO
          #{self.class.instance_variable_get(:@name)} (#{@columns})
        VALUES
          #{values}
      SQL
      
      @id = db.instance.last_insert_row_id
    else #updating entry
      raise "#{self} not in database" unless self.class.find_by_id(self.id)

      values = instance_variables.map { |var| 
        var.to_s[1..-1] + " = '" + instance_variable_get(var).to_s + "'" unless var == :@id
      }.select { |value| value != nil }

      db.instance.execute(<<-SQL)
        UPDATE
          #{self.class.instance_variable_get(:@name)}
        SET
          #{values.join(", ")}
        WHERE
          id = #{self.id}
      SQL
    end
  end
  alias_method :update, :save
end