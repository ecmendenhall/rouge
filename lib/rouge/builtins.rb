# encoding: utf-8

module Rouge::Builtins
  require 'rouge/compiler'

  SYMBOLS = {
    :nil => nil,
    :true => true,
    :false => false,
  }
end

class << Rouge::Builtins
  def let(context, bindings, *body)
    context = Rouge::Context.new context
    bindings.to_a.each_slice(2) do |k, v|
      destructure(context, k, v).each do |sk, sv|
        context.set_here sk.name, sv
      end
    end
    self.do(context, *body)
  end

  def _compile_let(ns, lexicals, bindings, *body)
    lexicals = lexicals.dup

    bindings = bindings.to_a.each_slice(2).flat_map do |k, v|
      v = Rouge::Compiler.compile(ns, lexicals, v)
      _compile_let_find_lexicals(lexicals, k)
      [k, v]
    end

    [Rouge::Symbol[:let],
     bindings,
     *Rouge::Compiler.compile(ns, lexicals, body)]
  end

  def _compile_let_find_lexicals(lexicals, form)
    if form.is_a?(Rouge::Symbol)
      lexicals << form.name
    elsif form.is_a?(Hash) and form.keys == [:keys]
      form.values[0].each do |n|
        lexicals << n.name
      end
    elsif form.is_a?(Hash)
      form.keys.each do |p|
        _compile_let_find_lexicals(lexicals, p)
      end
    elsif form.is_a?(Array)
      form = form.dup
      while form.length > 0
        p = form.shift

        next if p == :as
        next if p == Rouge::Symbol[:&]
        next if p == Rouge::Symbol[:|]

        _compile_let_find_lexicals(lexicals, p)
      end
    else
      raise ArgumentError, "unknown LHS of LET expression: #{form.inspect}"
    end
  end

  def context(context)
    context
  end

  def quote(context, form)
    form
  end

  def _compile_quote(ns, lexicals, form)
    [Rouge::Symbol[:quote], form]
  end

  def fn(context, *args)
    if args[0].is_a? Rouge::Symbol
      name = args.shift.to_sym
    end

    argv, *body = args

    if argv[-2] == Rouge::Symbol[:&]
      rest = argv[-1]
      argv = argv[0...-2]
    elsif argv[-4] == Rouge::Symbol[:&] and argv[-2] == Rouge::Symbol[:|]
      rest = argv[-3]
      argv = argv[0...-4] + argv[-2..-1]
    else
      rest = nil
    end

    if argv[-2] == Rouge::Symbol[:|]
      block = argv[-1]
      argv = argv[0...-2]
    else
      block = nil
    end

    original_argv = argv.dup.freeze

    fn = lambda {|*inner_args, &blockgiven|

      argv = original_argv.dup
      arity = inner_args.length

      if argv[1].is_a? Array
        p argv.to_a
        fun = argv.find {|f| f[1].length == arity } ||
              argv.find {|f| f[1].length > arity }
        _, argv, *body = fun

        if argv[-2] == Rouge::Symbol[:&]
          rest = argv[-1]
          argv = argv[0...-2]
        elsif argv[-4] == Rouge::Symbol[:&] and argv[-2] == Rouge::Symbol[:|]
          rest = argv[-3]
          argv = argv[0...-4] + argv[-2..-1]
        else
          rest = nil
        end

        if argv[-2] == Rouge::Symbol[:|]
          block = argv[-1]
          argv = argv[0...-2]
        else
          block = nil
        end
      end

      if !rest ? (inner_args.length != argv.length) :
        (inner_args.length < argv.length)
        begin
          raise ArgumentError,
            "wrong number of arguments " \
            "(#{inner_args.length} for #{argv.length})"
        rescue ArgumentError => e
          # orig = e.backtrace.pop
          # e.backtrace.unshift "(rouge):?:FN call (#{name || "<anonymous>"})"
          # e.backtrace.unshift orig
          raise e
        end
      end

      inner_context = Rouge::Context.new(context)

      argv.each.with_index do |arg, i|
        inner_context.set_here(arg.name, inner_args[i])
      end

      if rest
        inner_context.set_here(rest.name,
                               Rouge::Seq::Cons[*inner_args[argv.length..-1]])
      end

      if block
        inner_context.set_here(block.name, blockgiven)
      end

      begin
        self.do(inner_context, *body)
      rescue => e
        # e.backtrace.unshift "(rouge):?: in #{name || "<anonymous>"}"
        raise e
      end
    }

    if name
      fn.define_singleton_method(:to_s) { name }
    end

    fn
  end

  def _compile_fn(ns, lexicals, *args)
    if args[0].is_a? Rouge::Symbol
      name = args.shift
    end

    argv, *body = args

    original_argv = argv

    if argv[0].is_a? Array
      arities = []
      args.each do |form|
        arities <<  _compile_fn(ns, lexicals, *form)
      end
      return [Rouge::Symbol[:fn],
              *(name ? [name] : []),
              arities]
    end

    if argv[-2] == Rouge::Symbol[:&]
      rest = argv[-1]
      argv = argv[0...-2]
    elsif argv[-4] == Rouge::Symbol[:&] and argv[-2] == Rouge::Symbol[:|]
      rest = argv[-3]
      argv = argv[0...-4] + argv[-2..-1]
    else
      rest = nil
    end

    if argv[-2] == Rouge::Symbol[:|]
      block = argv[-1]
      argv = argv[0...-2]
    else
      block = nil
    end

    lexicals = lexicals.dup
    argv.each do |arg|
      lexicals << arg.name
    end
    lexicals << rest.name if rest
    lexicals << block.name if block

    compiled = [Rouge::Symbol[:fn],
     *(name ? [name] : []),
     original_argv,
     *Rouge::Compiler.compile(ns, lexicals, body)]
  end

  def def(context, name, *form)
    if name.ns != nil
      raise ArgumentError, "cannot def qualified var"
    end

    case form.length
    when 0
      context.ns.intern name.name
    when 1
      context.ns.set_here name.name, context.eval(form[0])
    else
      raise ArgumentError, "def called with too many forms #{form.inspect}"
    end
  end

  def _compile_def(ns, lexicals, name, *form)
    if name.ns != nil
      raise ArgumentError, "cannot def qualified var"
    end

    lexicals = lexicals.dup
    lexicals << name.name

    [Rouge::Symbol[:def],
     name,
     *Rouge::Compiler.compile(ns, lexicals, form)]
  end

  def if(context, test, if_true, if_false=nil)
    # Note that we rely on Ruby's sense of truthiness. (only false and nil are
    # falsey)
    if context.eval(test)
      context.eval if_true
    else
      context.eval if_false
    end
  end

  def do(context, *forms)
    r = nil

    while forms.length > 0
      begin
        form = Rouge::Compiler.compile(
          context.ns,
          Set[*context.lexical_keys],
          forms.shift)

        r = context.eval(form)
      rescue Rouge::Context::ChangeContextException => cce
        context = cce.context
      end
    end

    r
  end

  def _compile_do(ns, lexicals, *forms)
    [Rouge::Symbol[:do], *forms]
  end

  def ns(context, name, *args)
    ns = Rouge[name.name]
    ns.refer Rouge[:"ruby"]
    ns.refer Rouge[:"rouge.builtin"]

    unless name.name == :"rouge.core"
      ns.refer Rouge[:"rouge.core"]
    end

    args.each do |arg|
      kind, *params = arg.to_a

      case kind
      when :use
        params.each do |use|
          ns.refer Rouge[use.name]
        end
      when :require
        params.each do |param|
          if param.is_a? Rouge::Symbol
            Object.send :require, param.name.to_s
          elsif param.is_a? Array and
                param.length == 3 and
                param[0].is_a? Rouge::Symbol and
                param[1] == :as and
                param[2].is_a? Rouge::Symbol
            unless Rouge::Namespace.exists? param[0].name
              context.readeval(File.read("#{param[0].name}.rg"))
            end
            Rouge::Namespace[param[2].name] = Rouge[param[0].name]
          end
        end
      else
        raise "TODO bad arg in ns: #{kind}"
      end
    end

    context = Rouge::Context.new ns
    raise Rouge::Context::ChangeContextException, context
  end

  def _compile_ns(ns, lexicals, name, *args)
    [Rouge::Symbol[:ns], name, *args]
  end

  def defmacro(context, name, *parts)
    if name.ns
      raise ArgumentError, "cannot defmacro fully qualified var"
    end

    if parts[0].is_a? Array
      args, *body = parts
      macro = Rouge::Macro[
        context.eval(Rouge::Seq::Cons[Rouge::Symbol[:fn], args, *body])]
    elsif parts.all? {|part| part.is_a? Rouge::Seq::Cons}
      arities = {}

      parts.each do |cons|
        args, *body = cons.to_a

        if !args.is_a? Array
          raise ArgumentError,
              "bad multi-form defmacro component #{args.inspect}"
        end

        if args.index(Rouge::Symbol[:&])
          arity = -1
        else
          arity = args.length
        end

        if arities[arity]
          raise ArgumentError, "seen same arity twice"
        end

        arities[arity] =
            context.eval(Rouge::Seq::Cons[Rouge::Symbol[:fn], args, *body])
      end

      macro = Rouge::Macro[
        lambda {|*inner_args, &blockgiven|
          if arities[inner_args.length]
            arities[inner_args.length].call(*inner_args, &blockgiven)
          elsif arities[-1]
            arities[-1].call(*inner_args, &blockgiven)
          else
            raise ArgumentError, "no matching arity in macro"
          end
        }]
    else
      raise ArgumentError, "neither single-form defmacro nor multi-form"
    end

    macro.define_singleton_method(:to_s) { :"#{context.ns.name}/#{name.name}" }

    context.ns.set_here name.name, macro
  end

  def _compile_defmacro(ns, lexicals, name, *parts)
    if name.ns
      raise ArgumentError, "cannot defmacro fully qualified var"
    end

    if parts[0].is_a? Array
      args, *body = parts
      [Rouge::Symbol[:defmacro],
       name,
       *_compile_fn(ns, lexicals, args, *body)[1..-1]]
    elsif parts.all? {|part| part.is_a? Rouge::Seq::Cons}
      [Rouge::Symbol[:defmacro],
       name,
       *parts.map do |cons|
        args, *body = cons.to_a

        if !args.is_a? Array
          raise ArgumentError,
              "bad multi-form defmacro component #{args.inspect}"
        end

        Rouge::Seq::Cons[*_compile_fn(ns, lexicals, args, *body)[1..-1]]
       end]
    else
      raise ArgumentError, "neither single-form defmacro nor multi-form"
    end
  end

  def apply(context, fun, *args)
    args =
        args[0..-2].map {|f| context.eval f} +
        context.eval(args[-1]).to_a
    # This is a terrible hack.
    context.eval(Rouge::Seq::Cons[
        fun,
        *args.map {|a| Rouge::Seq::Cons[Rouge::Symbol[:quote], a]}])
  end

  def var(context, f)
    # HACK: just so it'll be found when fully qualified.
    f
  end

  def _compile_var(ns, lexicals, symbol)
    if symbol.ns
      [Rouge::Symbol[:quote], Rouge[symbol.ns][symbol.name]]
    else
      [Rouge::Symbol[:quote], ns[symbol.name]]
    end
  end

  def throw(context, throwable)
    exception = context.eval(throwable)
    begin
      raise exception
    rescue Exception => e
      # TODO
      #e.backtrace.unshift "(rouge):?:throw"
      raise e
    end
  end

  def try(context, *body)
    return unless body.length > 0

    form = body[-1]
    if form.is_a?(Rouge::Seq::Cons) and
       form[0].is_a? Rouge::Symbol and
       form[0].name == :finally
      finally = form[1..-1].freeze
      body.pop
    end

    catches = {}
    while body.length > 0
      form = body[-1]
      if !form.is_a?(Rouge::Seq::Cons) or
         !form[0].is_a? Rouge::Symbol or
         form[0].name != :catch
        break
      end

      body.pop
      catches[context.eval(form[1])] =
        {:bind => form[2],
         :body => form[3..-1].freeze}
    end

    r =
      begin
        self.do(context, *body)
      rescue Exception => e
        catches.each do |klass, caught|
          if klass === e
            subcontext = Rouge::Context.new context
            subcontext.set_here caught[:bind].name, e
            r = self.do(subcontext, *caught[:body])
            self.do(context, *finally) if finally
            return r
          end
        end
        self.do(context, *finally) if finally
        raise e
      end

    self.do(context, *finally) if finally
    r
  end

  def _compile_try(ns, lexicals, *body)
    return [Rouge::Symbol[:try]] unless body.length > 0

    form = body[-1]
    if form.is_a?(Rouge::Seq::Cons) and
       form[0].is_a? Rouge::Symbol and
       form[0].name == :finally
      finally = form[1..-1].freeze
      body.pop
    end

    catches = []
    while body.length > 0
      form = body[-1]
      if !form.is_a?(Rouge::Seq::Cons) or
         !form[0].is_a? Rouge::Symbol or
         form[0].name != :catch
        break
      end

      body.pop
      catches <<
        {:class => form[1],
         :bind => form[2],
         :body => form[3..-1].freeze}
    end

    form =
    [Rouge::Symbol[:try],
     *Rouge::Compiler.compile(ns, lexicals, body),
     *catches.reverse.map {|c|
      if !c[:bind].is_a?(Rouge::Symbol) or c[:bind].ns
        raise ArgumentError, "bad catch binding #{c[:bind]}"
      end

      bind_lexicals = lexicals.dup << c[:bind].name
      Rouge::Seq::Cons[Rouge::Symbol[:catch],
                  Rouge::Compiler.compile(ns, lexicals, c[:class]),
                  c[:bind],
                  *c[:body].map {|f|
                    Rouge::Compiler.compile(ns, bind_lexicals, f)
                  }]
    },
    *(finally ? [Rouge::Seq::Cons[Rouge::Symbol[:finally],
                             *finally.map {|f|
                               Rouge::Compiler.compile(ns, lexicals, f)
                             }]] : [])]
  end

  def destructure(context, parameters, values, evalled=false, r={})
    # TODO: can probably move this elsewhere as a regular function.

    if parameters.is_a?(Rouge::Symbol)
      values = context.eval(values) if !evalled
      r[parameters] = values
      return r
    end

    if parameters.is_a?(Hash) and parameters.keys == [:keys]
      keys = parameters.values[0]
      context.eval(values).select do |k,v|
        keys.include?(Rouge::Symbol[k])
      end.each {|k,v| r[Rouge::Symbol[k]] = v}
      return r
    end

    if parameters.is_a?(Hash)
      values = context.eval(values) if !evalled
      parameters.each do |local, foreign|
        destructure(context, local, values[foreign], true, r)
      end
      return r
    end

    if !parameters.is_a?(Array) and !evalled
      raise ArgumentError, "unknown destructure parameter list"
    end

    if !evalled and values.is_a? Array
      if values[-2] == Rouge::Symbol[:|]
        block = context.eval(values[-1])
        block_supplied = true

        values = values[0...-2]
      end

      if values[-2] == Rouge::Symbol[:&]
        values =
            values[0...-2].map {|v| context.eval(v)} +
            context.eval(values[-1]).to_a
      else
        values = values.map {|v| context.eval(v)}
      end
    else
      values = context.eval(values)
    end

    values = Rouge::Seq.seq(values)
    original_values = values

    parameters = parameters.dup
    while parameters.length > 0
      p = parameters.shift

      if p == Rouge::Symbol[:&]
        r[parameters.shift] = values
        values = Rouge::Seq::Empty
        next
      end

      if p == Rouge::Symbol[:|]
        if not block_supplied
          raise ArgumentError, "no block supplied"
        end

        r[parameters.shift] = block
        next
      end

      if p == :as
        r[parameters.shift] = Rouge::Seq.seq(original_values)
        values = Rouge::Seq::Empty
        next
      end

      if p.is_a? Array
        destructure(context, p, Rouge::Seq.seq(values.first), true, r)
      else
        if p.ns
          raise Rouge::Context::BadBindingError,
              "cannot let qualified name in DESTRUCTURE"
        end
        r[p] = values ? values.first : nil
      end

      values = values ? values.next : nil
    end

    r
  end

  def _compile_destructure(ns, lexicals, parameters, values)
    [Rouge::Symbol[:destructure],
     parameters,
     Rouge::Compiler.compile(ns, lexicals, values)]
  end
end

# vim: set sw=2 et cc=80:
