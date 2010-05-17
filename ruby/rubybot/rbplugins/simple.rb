=begin
**
** simple.rb
** 18/Apr/2007
**
** Desc:
**   Proof of concept Rubybot plugin that implements a simple echo service.
**  
** License:
**   This file is released under the terms of the Rubybot license. 
** See ../rubybot.rb for details.
**
=end
require 'rbplugins/plugin'

class SimplePlugin
  include Plugin
  def echo(args)  
    return "good to go: #{args.join('|')}"
  end
end


