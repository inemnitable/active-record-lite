require_relative './db_connection'

module Searchable
  def where(params)
    search_str = params.keys.map{ |k| "#{k} = ?" }.join(" AND ")
    query_result = DBConnection.execute(<<-SQL, *params.values)
    SELECT *
    FROM #{table_name}
    WHERE #{search_str}
    SQL

    parse_all(query_result)
  end
end