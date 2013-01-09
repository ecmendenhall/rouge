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
    Readline.completion_proc = Completer.new(context.ns)

    while true

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
        # Since completion is context sensitive, we need update the proc
        # whenever it changes.
        Readline.completion_proc = Completer.new(context.ns)
        count = 0
      rescue => e
        repl_error.call(e)
      end
    end
  end

  module Completer
    extend self

    # Returns a proc intended to be used with Readline.
    #
    # @param [Rouge::Namespace] current_namespace
    #   the current namespace
    #
    # @return [Proc] the completion proc to be used with Readline. The
    #   returned proc accepts a string and returns an array.
    #
    # @api public
    def new(current_namespace)
      return lambda do |query|
        if query.nil? || query.empty?
          return []
        end

        list = current_namespace.table.keys
        list << search(query)

        matches = search_list(list.flatten, query)

        # If there's only one match we check if it's a namespace or a Ruby
        # constant which contains other constants or singleton methods.
        if matches.length == 1
          match = matches[0]
          if Rouge::Namespace.exists?(match)
            if current_namespace.table.include?(match)
              matches << "#{match}/"
            else
              Readline.completion_append_character = "/"
            end
          else
            if locate_module(match.to_s)
              Readline.completion_append_character = ""
            end
          end
        else
          Readline.completion_append_character = ""
        end

        matches
      end
    end

    # Returns a list of constants and singleton method names based on the string
    # query.
    #
    # @param [String] query
    #   the search string to use
    #
    # @return [Array<Symbol,String>] the search results
    #
    # @api public
    def search(query)
      namespace, lookup = query.split('/', 2)
      result =
        case namespace
        # The ruby namespace requires special handling.
        when /^[A-Z]/
          search_ruby(query)
        when /^ruby/
          if lookup && lookup.empty?
            Rouge[:ruby].table.map {|x| "ruby/#{x}" }
          else
            search_ruby(lookup).map {|x| "ruby/#{x}" }
          end
        else
          ns = rg_namespaces[namespace.to_sym]

          if ns
            ns.table.map { |var, _| "#{namespace}/#{var}" }
          else
            # Add the current namepace, rouge.builtin, and ruby tables along with
            # the names of available namespaces in the completion list.
            list = []
            list << Rouge[:"rouge.builtin"].table.keys
            list << :ruby
            list << Rouge[:ruby].table
            list << rg_namespaces.keys
          end
        end

      search_list(result.flatten, query)
    end

    # Applies `locate_module` to the string query and returns a list constants
    # and singleton methods. These results are intended to be filtered in the
    # `search` method.
    #
    # @see Completer.locate_module, Completer.search
    #
    # @example
    #   search_ruby("Rouge") #=> ["Rouge/[]", "Rouge/boot!", ...]
    #   search_ruby("Rouge.") #=> ["Rouge/[]", "Rouge/boot!", ...]
    #
    # @param [String] query
    #   the search string to use
    #
    # @return [Array<Symbol,String>] the search result
    #
    # @api public
    def search_ruby(query)
      namespace = query.split('/', 2).first

      mod = locate_module(namespace)

      if mod == Object
        mod.constants
      else
        ns = mod.name.gsub('::','.')
        result = []
        mod.singleton_methods.each { |sm| result << "#{ns}/#{sm}" }
        mod.constants.each { |c| result << "#{ns}.#{c}" }
        result.flatten
      end
    end

    # Recursively searches for a Ruby module (includes classes) given by the
    # string query. The string should contain a Rouge style namespace name for
    # the module.
    #
    # Optionally, a root module can be supplied as the context for the query.
    # By default this is Object. If no module is found, the method returns nil
    # or the root.
    #
    # Be aware this method *only* returns modules and classes.
    #
    # @example
    #   locate_module("Bil.Bo") #=> Bil::Bo
    #   locate_module("Ji.Tsu", Nin) #=> Nin::Ji::Tsu
    #
    # @param [String] query
    #   the module (or class) to find
    #
    # @param [Module] root
    #   the optional search context
    #
    # @return [Class,Module,nil] the search result
    #
    # @api public
    def locate_module(query, root = Object)
      head, tail = query.split('.', 2)

      return root unless rg_ruby_module?(head)

      lookup = head.to_sym

      if root.is_a?(Module) && root.constants.include?(lookup)
        result = root.const_get(lookup)

        return root unless result.is_a?(Module)

        # `query` may have ended with '.'.
        if tail.nil? || tail.empty?
          result
        else
          locate_module(tail, result)
        end
      else
        root
      end
    end

    # Rouge namespaces. Note we do not include the rouge.builtin and ruby
    # namespaces since we would like built in vars, such as def or let, and top
    # level Ruby constants to be easily accessible with command line
    # completion.
    #
    # @return [Hash] the filtered namespaces
    #
    # @api public
    def rg_namespaces
      Rouge::Namespace.all.reject do |key, _|
        [:"rouge.builtin", :ruby].include?(key)
      end
    end

    private

    # Returns true if the string query matches a Rouge style Ruby module or
    # constant name.
    #
    # @param [String] query
    #   the query string to match.
    #
    # @return [Boolean]
    #
    # @api private
    def rg_ruby_module?(query)
      !!/^(?:[A-Z][A-Za-z_]*\.?)+$/.match(query)
    end

    # Filters a list of items based on a string query.
    #
    # @param [Array] list
    #   the list to filter.
    #
    # @param [String] query
    #   the search string to use.
    #
    # @return [Array]
    #
    # @api private
    def search_list(list, query)
      list.grep(/^#{Regexp.escape(query)}/)
    end
  end
end

# vim: set sw=2 et cc=80:
