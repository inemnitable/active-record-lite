require_relative './associatable'
require_relative './db_connection'
require_relative './mass_object'
require_relative './searchable'
require 'active_support/inflector'

class SQLObject < MassObject
  extend Searchable
  extend Associatable
  extend Relation

  def self.set_table_name(table_name = self.to_s.underscore)
    @table_name = table_name
  end

  def self.table_name
    @table_name || self.to_s.underscore
  end

  def self.all
    relation = Relation.new(self)

    # query_result = DBConnection.execute(<<-SQL)
#     SELECT * FROM #{table_name}
#     SQL
    relation.execute.first
  end

  def self.find(id)
    relation = Relation.new(self).where("id = ?", id)

    # new(DBConnection.execute(<<-SQL, id).first)
#     SELECT * FROM #{table_name} WHERE id = ?
#     SQL
    relation.execute
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


  #find_by_arbitary_attribute
  def self.method_missing(method_name, *args)
    method_name = method_name.to_s
    super unless method_name.start_with?("find_by_")
    attr_name = method_name[8..-1]
    attr_value = args.first
    results = DBConnection.execute(<<-SQL, attr_value)
    SELECT * FROM #{table_name} WHERE #{attr_name} = ?
    SQL
    parse_all(results)
  end
end
