require_relative './associatable'
require_relative './db_connection'
require_relative './mass_object'
require_relative './searchable'
require 'active_support/inflector'

class SQLObject < MassObject
  extend Searchable
  extend Associatable

  def self.set_table_name(table_name = self.to_s.underscore)
    @table_name = table_name
  end

  def self.table_name
    @table_name || self.to_s.underscore
  end

  def self.all
    query_result = DBConnection.execute(<<-SQL)
    SELECT * FROM #{table_name}
    SQL

    parse_all(query_result)
  end

  def self.find(id)
    new(DBConnection.execute(<<-SQL, id).first)
    SELECT * FROM #{table_name} WHERE id = ?
    SQL
  end

  def create
    attrs = self.class.attributes
    values = attribute_values
    question_marks = (['?'] * attrs.length).join(", ")
    DBConnection.execute(<<-SQL, *values)
    INSERT INTO #{self.class.table_name} (#{attrs.join(", ")})
         VALUES (#{question_marks})
    SQL
    @id = DBConnection.last_insert_row_id
  end

  def update
    attrs = self.class.attributes
    values = attribute_values
    set_str = attrs.map { |attrib| "#{attrib} = ?" }.join(", ")
    DBConnection.execute(<<-SQL, *values)
    UPDATE #{self.class.table_name} SET #{set_str} WHERE id = #{@id}
    SQL
  end

  def save
    if @id.nil?
      create
    else
      update
    end
  end

  def attribute_values
    self.class.attributes.map { |attribute| send(attribute) }
  end
end
