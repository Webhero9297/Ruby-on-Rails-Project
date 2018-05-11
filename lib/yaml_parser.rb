require 'gettext/utils'
require 'gettext/tools/rgettext'
module YMLParser
  module_function

  def target?(file)
    File.extname(file) == '.yml'
  end
  
  def parse(file)
    $return_ary = []
    $levels_ary = []
    data = YAML::load(IO.readlines(file).join)
    data.each do |key,value|
      if value.kind_of? Hash
        recurs(value)
      end
      
    end
    return $return_ary.map{ |item| [item, file] }
  end
  
  def recurs(dict)
    dict.each do |key, value|
      $levels_ary.push(key)
      if value.kind_of? Hash
        recurs(value)
      end
      if value.kind_of? String
        $return_ary.push( $levels_ary.join('.') )
      end
      $levels_ary.pop()
    end
  end
  
  
end
GetText::RGetText.add_parser(YMLParser)