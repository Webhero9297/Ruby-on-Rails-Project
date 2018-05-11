module StringToBoolean
  def to_bool
    return true if self == true || self =~ (/^(true|t|yes|y|1)$/i)
    return false if self == false || self.blank? || self =~ (/^(false|f|no|n|0)$/i)
    raise ArgumentError.new("invalid value for Boolean: \"#{self}\"")
  end
end
class String; include StringToBoolean; end

module BooleanToBoolean
  def to_bool;return self; end
end

class TrueClass; include BooleanToBoolean; end
class FalseClass; include BooleanToBoolean; end
