require 'hammerspace'
h = Hammerspace.new("/tmp/hammerspace")

h["cartoons"] = "mallets"
h["games"]    = "inventory"
h["rubyists"] = "data"

h.size          #=> 3
h["cartoons"]   #=> "mallets"

h.map { |k,v| "#{k.capitalize} use hammerspace to store #{v}." }

h.close