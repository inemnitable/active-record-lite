require 'active_support/core_ext/object/try'
require 'active_support/inflector'
require_relative './db_connection.rb'

class AssocParams
  attr_accessor :primary_key, :foreign_key

  def other_class
    @other_class_name.constantize
  end

  def other_table
    other_class.table_name
  end
end

class BelongsToAssocParams < AssocParams
  def initialize(name, params)
    @name = name
    @other_class_name = params[:class_name] || name.to_s.camelize
    @primary_key = params[:primary_key] || :id
    @foreign_key = params[:foreign_key] || (name.to_s << "_id").to_sym
  end

  def type
    :belongs_to
  end
end

class HasManyAssocParams < AssocParams
  def initialize(name, params, self_class)
    @name = name
    @other_class_name = params[:class_name] || name.to_s.singularize.camelize
    @primary_key = params[:primary_key] || :id
    @foreign_key = params[:foreign_key] ||
                  (self_class.to_s.underscore << "_id").to_sym
  end

  def type
    :has_many
  end
end

module Associatable
  def assoc_params
    @assoc_params || @assoc_params = {}
  end

  def belongs_to(name, params = {})
    aps = BelongsToAssocParams.new(name, params)
    assoc_params[name] = aps

    define_method(name) do
      query_result = DBConnection.execute(<<-SQL, self.send(aps.foreign_key))
      SELECT *
      FROM #{aps.other_table}
      WHERE #{aps.other_table}.#{aps.primary_key} = ?
      SQL
      aps.other_class.parse_all(query_result).first
    end
  end

  def has_many(name, params = {})
    aps = HasManyAssocParams.new(name, params, self.class)
    assoc_params[name] = aps

    define_method(name) do
      query_result = DBConnection.execute(<<-SQL, self.send(aps.primary_key))
      SELECT *
      FROM #{aps.other_table}
      WHERE #{aps.other_table}.#{aps.foreign_key} = ?
      SQL
      aps.other_class.parse_all(query_result)
    end
  end

  def has_one_through(name, assoc1, assoc2)
    define_method(name) do
      params1 = self.class.assoc_params[assoc1]
      params2 = params1.other_class.assoc_params[assoc2]
      query_result = DBConnection.execute(<<-SQL, self.send(params1.foreign_key))
      SELECT #{params2.other_table}.*
      FROM #{params2.other_table}
      JOIN #{params1.other_table}
      ON #{params2.other_table}.#{params2.primary_key} =
         #{params1.other_table}.#{params2.foreign_key}
      WHERE #{params1.other_table}.#{params1.primary_key} = ?
      SQL

      params2.other_class.parse_all(query_result).first
    end
  end
end
