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
    bindings.each_slice(2) do |k, v|
      context.set_here k.name, context.eval(v)
    end
    self.do(context, *body)
  end

  def _compile_let(ns, lexicals, bindings, *body)
    lexicals = lexicals.dup

    bindings = bindings.each_slice(2).map do |k, v|
      if k.ns
        raise Rouge::Context::BadBindingError,
            "cannot LET qualified name"
      end
      v = Rouge::Compiler.compile(ns, lexicals, v)
      lexicals << k.name
      [k, v]
    end.flatten(1)
    [Rouge::Symbol[:let],
     bindings,
     *Rouge::Compiler.compile(ns, lexicals, body)]
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
      name = args.shift.name
    end

    argv, *body = args

    context = Rouge::Context.new(context)

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

    fn = lambda {|*args, &blockgiven|
      if !rest ? (args.length != argv.length) : (args.length < argv.length)
        begin
          raise ArgumentError,
              "wrong number of arguments (#{args.length} for #{argv.length})"
        rescue ArgumentError => e
          orig = e.backtrace.pop
          e.backtrace.unshift "(rouge):?:FN call (#{name || "<anonymous>"})"
          e.backtrace.unshift orig
          raise e
        end
      end

      argv.each.with_index do |arg, i|
        context.set_here(arg.name, args[i])
      end
      context.set_here(rest.name, Rouge::Cons[*args[argv.length..-1]]) if rest
      context.set_here(block.name, blockgiven) if block

      begin
        self.do(context, *body)
      rescue => e
        e.backtrace.unshift "(rouge):?: in #{name || "<anonymous>"}"
        raise e
      end
    }

    if name
      fn.define_singleton_method(:name) { name }
    end

    fn
  end

  def _compile_fn(ns, lexicals, *args)
    if args[0].is_a? Rouge::Symbol
      name = args.shift
    end

    argv, *body = args

    original_argv = argv

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

    [Rouge::Symbol[:fn],
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
    ns.refer Rouge[:"rouge.builtin"]

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
            Kernel.require param.name.to_s
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
        context.eval(Rouge::Cons[Rouge::Symbol[:fn], args, *body])]
    elsif parts.all? {|part| part.is_a? Rouge::Cons}
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
            context.eval(Rouge::Cons[Rouge::Symbol[:fn], args, *body])
      end

      macro = Rouge::Macro[
        lambda {|*args, &blockgiven|
          if arities[args.length]
            arities[args.length].call *args, &blockgiven
          elsif arities[-1]
            arities[-1].call *args, &blockgiven
          else
            raise ArgumentError, "no matching arity in macro"
          end
        }]
    else
      raise ArgumentError, "neither single-form defmacro nor multi-form"
    end

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
    elsif parts.all? {|part| part.is_a? Rouge::Cons}
      [Rouge::Symbol[:defmacro],
       name,
       *parts.map do |cons|
        args, *body = cons.to_a

        if !args.is_a? Array
          raise ArgumentError,
              "bad multi-form defmacro component #{args.inspect}"
        end

        Rouge::Cons[*_compile_fn(ns, lexicals, args, *body)[1..-1]]
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
    context.eval(Rouge::Cons[
        fun,
        *args.map {|a| Rouge::Cons[Rouge::Symbol[:quote], a]}])
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
    if form.is_a?(Rouge::Cons) and
       form[0].is_a? Rouge::Symbol and
       form[0].name == :finally
      finally = form[1..-1].freeze
      body.pop
    end

    catches = {}
    while body.length > 0
      form = body[-1]
      if !form.is_a?(Rouge::Cons) or
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
    if form.is_a?(Rouge::Cons) and
       form[0].is_a? Rouge::Symbol and
       form[0].name == :finally
      finally = form[1..-1].freeze
      body.pop
    end

    catches = []
    while body.length > 0
      form = body[-1]
      if !form.is_a?(Rouge::Cons) or
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
      Rouge::Cons[Rouge::Symbol[:catch],
                  Rouge::Compiler.compile(ns, lexicals, c[:class]),
                  c[:bind],
                  *c[:body].map {|f|
                    Rouge::Compiler.compile(ns, bind_lexicals, f)
                  }]
    },
    *(finally ? [Rouge::Cons[Rouge::Symbol[:finally],
                             *finally.map {|f|
                               Rouge::Compiler.compile(ns, lexicals, f)
                             }]] : [])]
  end

  def destructure(context, parameters, values, evalled=false, r={})
    # TODO: can probably move this elsewhere as a regular function.
    i = 0

    if !parameters.is_a?(Array) and !evalled
      return {parameters => context.eval(values)}
    end
    
    unless evalled
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
        values =
            values.map {|v| context.eval(v)}
      end
    else
      values = values.dup
    end
    
    parameters = parameters.dup
    while parameters.length > 0
      p = parameters.shift

      if p == Rouge::Symbol[:&]
        r[parameters.shift] = values.freeze
        values = []
        next
      end

      if p == Rouge::Symbol[:|]
        if not block_supplied
          raise ArgumentError, "no block supplied"
        end

        r[parameters.shift] = block
        next
      end

      if values.length == 0
        raise ArgumentError, "fewer values than parameters"
      end

      if p.is_a? Array
        destructure(context, p, values.shift, true, r)
      else
        r[p] = values.shift
      end
    end

    if values.length > 0
      raise ArgumentError, "fewer parameters than values"
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
