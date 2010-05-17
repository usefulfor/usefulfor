module Plugin
  attr :msg 

  # part is a TMail::Mail
  def part_filename(part)
    # This is how TMail::Attachment gets a filename
    file_name = (part['content-location'] &&
      part['content-location'].body) ||
      part.sub_header("content-type", "name") ||
      part.sub_header("content-disposition", "filename")
  end

  CTYPE_TO_EXT = {
    'image/jpeg' => 'jpg',
    'image/gif'  => 'gif',
    'image/png'  => 'png',
    'image/tiff' => 'tif'
  }
  
  def ext(mail)
    CTYPE_TO_EXT[mail.content_type] || 'txt'
  end

  # email is a TMail::Mail
  def save(folder)
    #email.attachments are TMail::Attachment
    @atch = []

    FileUtils.mkdir_p(folder)
    #body = email.parts.shift
    if (@msg.parts.empty?)
      @log.info{ "no parts detected (only message body)" }
    else
      idx = 1
      @log.info{ "message consisting of #{@msg.parts.size} parts" }
      @msg.parts.each do |part|
        filename = part_filename(part)
        filename = "#{idx}.#{ext(part)}" if filename.nil? || filename.length == 0
        @atch << filename
        filepath = folder + '/' + filename
        @log.info{ "WRITING: #{filepath}" }
        File.open(filepath,File::CREAT|File::TRUNC|File::WRONLY,0644){ |f|
          f.write(part.body)
        }
        idx += 1
      end
    end
  end
  
  def clear(folder)
    @log.debug{ "clearing contents of #{folder}"}
    Dir["#{folder}/*.*"].each{|x| 
      if (!File.symlink?(x)) 
        File.delete(x) 
      end
    }
  end

  def process(mail, options)
    @msg = mail
    @opt = options
    @log = options[:logger]

    #save the attachments to the tmp dir
    @log.debug {"saving the attachments to the tmp [#{@opt[:tmpdir]}]"}
    save(@opt[:tmpdir])

    #process the body, 1 command per line
    if (@msg.parts.empty?)
      commands = @msg.body.split(/\n/)
    else
      commands = @msg.parts[0].body.split(/\n/)
    end

    @log.info('plugin') { "processing #{commands.size} command(s)" }
    out = []
    
    commands.each do |cmdline|
      args = cmdline.split
      if (self.respond_to?(args[0]))
        begin
          @log.info( 'plugin' ) { "[#{args[0]}] processed by #{args[0]} plugin. " }
          out << self.send(args[0], *args[1,args.size-1])
        rescue
          @log.error('plugin') { "error while processing command: #{$!}" }
          @log.debug('plugin') { $!.backtrace.join("\n") }
          out << "error while processing command: #{$!}"
        end
      else
        @log.error('plugin') { "undefined command: #{args[0]}" }
        out << '<command not found / no output from command>'
      end
    end

    #clear the temp dir
    clear(@opt[:tmpdir])

    return out
  end

end

