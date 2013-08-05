class MassObject
  def self.set_attrs(*attributes)
    @attributes = attributes
    attributes.each do |attribute|
      self.send(:attr_accessor, attribute)
    end
  end

  def self.attributes
    @attributes
  end

  def self.parse_all(results)
    results.map { |row_hash| new(row_hash) }
  end

  def initialize(params = {})
    params.each do |k, v|
      unless self.class.attributes.include?(k.to_sym)
        raise "mass assignment to unregistered attribute #{k}"
      end
      self.instance_variable_set("@#{k}", v)
    end
  end
end
