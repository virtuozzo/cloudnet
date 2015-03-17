class String
  def to_number
    Integer(self) rescue nil
  end
end