# encoding: utf-8
require 'rouge/wrappers'
require 'rouge/namespace'

class Rouge::Context
  class BindingNotFoundError < StandardError; end
  class BadBindingError < StandardError; end
  class ChangeContextException < Exception
    def initialize(context); @context = context; end
    attr_reader :context
  end

  def initialize(parent_or_ns)
    case parent_or_ns
    when Rouge::Namespace
      @ns = parent_or_ns
    when Rouge::Context
      @parent = parent_or_ns
      @ns = @parent.ns
    end
    @table = {}
  end

  def [](key)
    if @table.include? key
      @table[key]
    elsif @parent
      @parent[key]
    elsif @ns
      @ns[key]
    else
      raise BindingNotFoundError, key
    end
  end

  def set_here(key, value)
    if Rouge::Symbol[key].ns != nil
      raise BadBindingError, "cannot bind #{key.inspect}"
    end

    @table[key] = value
  end

  def set_lexical(key, value)
    if @table.include? key
      @table[key] = value
    elsif @parent
      @parent.set_lexical key, value
    else
      raise BindingNotFoundError,
          "setting #{key} to #{value.inspect}"
    end
  end

  def lexical_keys
    @table.keys + (@parent ? @parent.lexical_keys : [])
  end

  #   This readeval post-processes the backtrace.  Accordingly, it should only
  # be called by consumers, and never by Rouge internally itself, lest it
  # catches an exception and processes the backtrace too early.
  def readeval(input)
    reader = Rouge::Reader.new(ns, input)
    context = self
    r = nil

    while true
      begin
        form = reader.lex
      rescue Rouge::Reader::EndOfDataError
        return r
      end

      form = Rouge::Compiler.compile(context.ns, Set[*lexical_keys], form)

      begin
        r = context.eval(form)
      rescue ChangeContextException => cce
        context = cce.context
        reader.ns = context.ns
      end
    end
  rescue Exception => e
    # Remove Rouge-related lines unless the exception originated in Rouge.
    root = File.dirname(File.dirname(__FILE__))
    e.backtrace.map! {|line|
      line.scan(root).length > 0 ? nil : line
    }.compact! unless e.backtrace[0].scan(root).length > 0
    raise e
  end

  # Internal use only -- doesn't post-process backtrace.
  def eval(form)
    case form
    when Rouge::Compiler::Resolved
      result = form.res
      if result.is_a?(Rouge::Var)
        result.deref
      else
        result
      end
    when Rouge::Symbol
      eval_symbol form
    when Rouge::Seq::Cons
      eval_cons form
    when Hash
      Hash[form.map {|k,v| [eval(k), eval(v)]}].freeze
    when Array
      form.map {|f| eval(f)}.freeze
    else
      form
    end
  end

  # +symbol+ should be a Rouge::Symbol.
  def locate(symbol)
    if !symbol.is_a?(Rouge::Symbol)
      raise ArgumentError, "locate not called with R::S"
    elsif symbol.ns
      raise ArgumentError, "locate called with NS'd R::S #{symbol}"
    end

    if symbol.name_s[-1] == ?. and symbol.name_s.length > 1
      lambda {|*args, &block|
        self[symbol.name_s[0..-2].intern].new(*args, &block)
      }
    else
      self[symbol.name]
    end
  end

  attr_reader :ns

  private

  def eval_symbol(form)
    if !form.ns and form.name_s[0] == ?. and form.name_s.length > 1
      lambda {|receiver, *args, &block|
        receiver.send(form.name_s[1..-1], *args, &block)
      }
    else
      result = locate form
      if result.is_a?(Rouge::Var)
        result.deref
      else
        result
      end
    end
  end

  def eval_cons(form)
    fun = eval form[0]

    case fun
    when Rouge::Builtin
      backtrace_fix("(rouge):?:builtin: ", form) do
        fun.inner.call self, *form.to_a[1..-1]
      end
    else
      args = form.to_a[1..-1]

      if args.include? Rouge::Symbol[:|]
        index = args.index Rouge::Symbol[:|]
        if args.length == index + 2
          # Function.
          block = eval args[index + 1]
        else
          # Inline block.
          block = eval(Rouge::Seq::Cons[Rouge::Symbol[:fn],
                                   args[index + 1],
                                   *args[index + 2..-1]])
        end
        args = args[0...index]
      else
        block = nil
      end

      args = args.map {|f| eval(f)}

      backtrace_fix("(rouge):?:lambda: ", form) do
        fun.call *args, &block
      end
    end
  end

  def backtrace_fix name, form, &block
    begin
      block.call
    rescue Exception => e
      target = block.source_location.join(':')
      changed = 0
      $!.backtrace.map! {|line|
        if line.scan("#{target}:").size > 0 and changed == 0
          changed += 1
          Rouge.print(form, name.dup)
        else
          line
        end
      }
      raise e
    end
  end
end

# vim: set sw=2 et cc=80:
