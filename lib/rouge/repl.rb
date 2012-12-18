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
      if not chaining
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
      rescue Rouge::Reader::EndOfDataError
        chaining = true
        next
      rescue Rouge::Reader::UnexpectedCharacterError => reader_err
        repl_error.call reader_err
      rescue Rouge::Reader::NumberFormatError => reader_err
        repl_error.call reader_err
      end

      chaining = false

      begin
        form = Rouge::Compiler.compile(
          context.ns,
          Set[*context.lexical_keys],
          form
        )

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
        repl_error.call e
      end
    end
  end

end

# vim: set sw=2 et cc=80:
