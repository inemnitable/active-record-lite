class Relation

  @@result_cache = {}

  values = nil

  def execute
    cached = @@result_cache[[@sql_fragments, @values]]
    return cached if cached

    values = @values[:select] + @values[:from] + @values[:joins] + @values[:where]
    results = DBConnection.execute(<<-SQL, *values)
    #{sql_fragments[:select]}
    #{sql_fragments[:from]}
    #{sql_fragments[:joins]}
    #{sql_framgents[:where]}
    SQL
    ret = parse_all(results)
    @@result_cache[[@sql_fragments, @values]] = ret
  end

  def initialize(values = [], fragments = {})
    Binding.of_caller do |b|
      @result_cache = nil
      @sql_fragments = fragments
      @sql_fragments[:select] ||= "SELECT #{b[:table_name]}.*"
      @sql_fragments[:from] ||= "FROM #{b[:table_name]}"
      @values = values
    end
  end

  [:select, :from, :where, :joins].each do |method_name|
    define_method(method_name) do |fragment, *values|
      @sql_fragments[method_name] = fragment
      @values[method_name] = values
      self
    end
  end

end