require 'gettext/utils'
require 'gettext/tools/rgettext'
module HTMLParser
  module_function

  def target?(file)
    File.extname(file) == '.erb'
  end
  
  def parse(file, ary=[])
    data = IO.readlines(file).join
    msgid_re = /'(.*?)'/m
    comments_re = /({.*?})/m
    gettext_re = /_\((.*?)\)/m
    data.scan(gettext_re) do |hit|
      hit = hit[0]
      msgid = msgid_re.match(hit)[1] unless msgid_re.match(hit).nil?
      if comments_re.match(hit).nil?
        ary.push([msgid, file])
        next
      end
      comments = comments_re.match(hit)[1]
      ary.push([msgid, comments])
    end
    puts ary.inspect
    return ary
  end
  
  
  
end
GetText::RGetText.add_parser(HTMLParser)