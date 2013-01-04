# encoding: utf-8
require 'readline'

module Rouge::REPL

  def self.run!(options = {:backtrace => true})
    puts "Rouge #{Rouge::VERSION}"

    repl_error = lambda do |e|
      STDOUT.puts "!! #{e.class}: #{e.message}"

      if options[:backtrace]
        STDOUT.puts "#{e.backtrace.join "\n"}"
      end
    end

    context = Rouge::Context.new(Rouge[:user])
    count = 0
    chaining = false

    while true
      # Since completion is context sensitive we need update the completion proc
      # upon each iteration.
      Readline.completion_proc = completion_proc(context.ns)

      if !chaining
        prompt = "#{context.ns.name}=> "
        input = Readline.readline(prompt, true)
      else
        prompt = "#{" " * [0, context.ns.name.length - 2].max}#_=> "
        input << "\n" + Readline.readline(prompt, true)
      end

      if input.nil?
        STDOUT.print "\n"
        break
      end

      begin
        form = context.ns.read(input)
      rescue Rouge::Reader::EOFError
        next
      rescue Rouge::Reader::EndOfDataError
        chaining = true
        next
      rescue Rouge::Reader::UnexpectedCharacterError => reader_err
        repl_error.call(reader_err)
      rescue Rouge::Reader::NumberFormatError => reader_err
        repl_error.call(reader_err)
      end

      chaining = false

      begin
        form = Rouge::Compiler.compile(context.ns,
                                       Set[*context.lexical_keys],
                                       form)

        result = context.eval(form)

        Rouge.print(result, STDOUT)
        STDOUT.puts

        count += 1 if count < 10
        count.downto(2) do |i|
          context.set_here :"*#{i}", context[:"*#{i - 1}"]
        end
        context.set_here :"*1", result
      rescue Rouge::Context::ChangeContextException => cce
        context = cce.context
        count = 0
      rescue => e
        repl_error.call(e)
      end
    end
  end

  # Returns a proc intended to be used with Readline.
  #
  # @param [Rouge::Namespace] the current namespace
  #
  # @return [Proc<String>] the completion proc to be used with Readline. The
  #   returned proc accepts a string and returns an array.
  #
  # @api public
  #
  def self.completion_proc(current_namespace)
    return proc do |search|
      list = []

      # Rouge namespaces. Note we do not include the rouge.builtin and ruby
      # namespaces since we would like built in vars, such as def or let, and
      # top level Ruby constants to be easily accessible with command line
      # completion (see below).
      rg_namespaces = Rouge::Namespace.all.reject do |key, _|
        [:"rouge.builtin", :ruby].include?(key)
      end

      if /\//.match(search)
        namespace = search.split('/').first.to_sym

        # The ruby namespace requires special handling.
        if /^ruby/.match(namespace)
          list << Rouge[namespace].table.map do |constant|
            "ruby/#{constant}"
          end
        else
          lookup = rg_namespaces[namespace.to_sym]

          if lookup
            list << lookup.table.map do |var_name, _|
              "#{namespace}/#{var_name}"
            end
          end
        end
      else
        # Add the current namepace, rouge.builtin, rouge.coure, and ruby tables
        # along with the names of available namespaces in the completion list.
        list << current_namespace.table
        list << Rouge[:"rouge.builtin"].table.keys
        list << Rouge[:"rouge.core"].table.keys
        list << :ruby
        list << Rouge[:ruby].table
        list << rg_namespaces.keys
      end

      matches = list.flatten.grep(/^#{search}/)

      # If there's only one match we check if it's a namespace. If it is we
      # we use the solidus as the completion character, otherwise we append
      # the namespace (including solidus) to the list.
      if matches.length == 1 && Rouge::Namespace.exists?(matches[0])
        match = matches[0]

        if current_namespace.table.include?(match)
          matches << "#{match}/"
        else
          Readline.completion_append_character = "/"
        end
      else
        Readline.completion_append_character = ""
      end

      matches
    end
  end
end

# vim: set sw=2 et cc=80:
