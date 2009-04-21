module ImExport
  def self.import(file_name, options = {})
  
    ## e.g. :seminar => "seminar" => "Seminar" => Seminar
    model = Kernel.const_get(options[:class_name].to_s.classify)
    
    ## used to check for an existing record. so we do update_attributes()
    # instead of save() in that case
    find_method = "find_by_#{options[:find_by]}"
    
    ## helps to distinguish between real columns and column content
    # could be something like "COLUMN_"
    columns_prefix = options[:db_columns_prefix].to_s
    
    ## for each line, this is how we check for a new column or cont.
    # from the previous line
    scan_regexp = Regexp.new("^\\s*#{columns_prefix}(\\w+)\\: (.*)")
    
    ## table columns --> model attributes mapping
    # if an attribute is not specified and present as a column,
    # it'll try figure it out:
    # { 'title' => :title } - works w/o expicit mapping
    attr_map = options[:map] || {}
    
    ## Read the file
    # we assume it's been created with vertial columns layout (mysql -E ...)
    IO.foreach(file_name) do |line|
      ## mysql -E ... does this:
      # ********* 1. row **********
      # column: value
      # another_column: value
      # ********* 2. row **********
      unless (line =~ /^\*+ \d+\. row \*+$/).nil?
        ## We've got a new row
        unless block_given?
          ## Save previously created object ...
          if !@model.nil? and @model.valid?
            if (s = model.send("#{find_method}", @model.title))
              s.update_attributes(@model.attributes.reject{|k,v| v.nil?})
            else
              @model.save
            end
          else 
            $stderr.puts "\n>>> ERRORS while storing #{options[:class_name]}: #{@model.errors.full_messages.join('; ')}\n#{@model.inspect}" unless @model.nil?
          end
        else
          ## or pass it to a block
          # in this case we don't do any validations
          yield(@model)
        end
        
        # ... then create a new one
        #$stderr.puts "\n###################################"
        @model = model.new
        @last_column_name = nil
        @last_column_content = nil
        next
      end
      
      ## Cont. of the same row.
      ## It's one table column at a time (or more lines).
      ## Parse it and add set the corresponding attribute in the model
      line.chomp!
      column = line.scan(scan_regexp)
      #$stderr.puts column.inspect
      
      unless column.size > 0
        ## this is a column continuation of the previous line
        @last_column_content << '<br/>' << line
        next
      end
      
      ## this is a new model attribute
      # set last attribute in the model if defined
      # we should have at least two items in the array
      column.flatten!
      @last_column_name = column.first
      @last_column_content = column[1].gsub(/\t+/, " ").strip.gsub(/^\n+$/, "").gsub(/\n+/, "<br/>")
      
      # in column-to-model map
      if attr_map.include?(@last_column_name)
        mattr = attr_map[@last_column_name]
        case
          when mattr.kind_of?(Symbol)
            @model.send("#{mattr.to_s}=", @last_column_content)
          when mattr.kind_of?(Proc)
            mattr.call(@last_column_content, @model)
          when mattr.kind_of?(Hash)
            @model.send("#{mattr.keys.first}=", mattr.values.first.call(@last_column_content))
          else
            $stderr.puts "WARNING: don't know how to handle #{mattr.inspect}"
        end
        
      # simple auto-mapping  
      elsif @model.respond_to?(@last_column_name.to_sym)
        @model.send("#{@last_column_name}=", @last_column_content)
        
      # otherwise we don't know how to do it
      else
        $stderr.puts "WARNING: don't know how to set :#{@last_column_name}"
      end
    end # IO.foreach
  end
end
