require 'gettext/utils'
require 'gettext/tools/rgettext'
module MongodbParser
  module_function
  # If the file is the target of your parser, then return true, otherwise false.
  def target?(file)
    File.extname(file) == ".mongo"  # This parser targets csv files only.
  end
  # Parse a file and return the array of PoMessages.
  def parse(file, ary = [])
    puts "Starting MongoDB parsing..."
    IO.foreach(file) do |block|
      puts "Model: #{block}"
       current_model = eval(block)
       current_model.all.each do |row|
         ary.push([row['msgid'], "model.#{block}"])
      end
    end
    puts "MongoDB parsing done!"
    return ary
  end
end
# Add this parser to GetText::RGetText
GetText::RGetText.add_parser(MongodbParser)
