# encoding: utf-8
require 'set'

module Rouge::Compiler
  class Resolved
    def initialize(res)
      @res = res
    end

    attr_reader :res
  end

  def self.compile(ns, lexicals, form)
    case form
    when Rouge::Symbol
      name = form.name
      is_new = (name[-1] == ?. and name.length > 1)
      name = name[0..-2].to_sym if is_new

      if !form.ns and
         (lexicals.include?(name) or
          (name[0] == ?. and name.length > 1) or
          [:|, :&].include?(name))
        # TODO: cache found ns/var/context or no. of context parents.
        form
      else
        if form.ns and !Rouge::Namespace.get(form.ns)
          # ns specified but no actual namespace so-called.
          if form.ns["/"]
            # ns/Const/method ?
            method = form.name
            form = Rouge::Symbol[form.ns]
          else
            # Const/method ?
            method = form.name
            form = Rouge::Symbol[form.ns]
          end
        end

        resolved = form.ns ? Rouge[form.ns] : ns

        lookups = form.name_parts
        resolved = resolved[lookups[0]]
        i, count = 1, lookups.length

        while i < count
          resolved = resolved.deref if resolved.is_a?(Rouge::Var)
          resolved = resolved.const_get(lookups[i])
          i += 1
        end

        if is_new
          klass = resolved
          klass = klass.deref if klass.is_a?(Rouge::Var)
          resolved = klass.method(:new)
        end

        if method
          receiver = resolved
          receiver = receiver.deref if receiver.is_a?(Rouge::Var)
          resolved = receiver.method(method)
        end

        Resolved.new resolved
      end
    when Array
      form.map {|f| compile(ns, lexicals, f)}
    when Hash
      Hash[form.map {|k, v| [compile(ns, lexicals, k),
                             compile(ns, lexicals, v)]}]
    when Rouge::Seq::ISeq
      to_a = form.to_a
      if to_a.empty?
        return Rouge::Seq::Empty
      end

      head, *tail = to_a

      if head.is_a?(Rouge::Symbol) and
         (head.ns.nil? or head.ns == :"rouge.builtin") and
         Rouge::Builtins.respond_to?("_compile_#{head.name}")
        Rouge::Seq::Cons[*
          Rouge::Builtins.send(
            "_compile_#{head.name}",
            ns, lexicals, *tail)]
      else
        head = compile(ns, lexicals, head)

        # XXX ↓↓↓ This is insane ↓↓↓
        if head.is_a?(Resolved) and
           head.res.is_a?(Rouge::Var) and
           head.res.deref.is_a?(Rouge::Macro)
          # TODO: backtrace_fix
          compile(ns, lexicals, head.res.deref.inner.call(*tail))
        else
          # Regular function call!
          if tail.include? Rouge::Symbol[:|]
            index = tail.index Rouge::Symbol[:|]
            if tail.length == index + 2
              # Function.
              block = compile(ns, lexicals, tail[index + 1])
            else
              # Inline block.
              block = compile(
                ns, lexicals,
                Rouge::Seq::Cons[Rouge::Symbol[:fn],
                            *tail[index + 1..-1]])
            end
            tail = tail[0...index]
          else
            block = nil
          end
          Rouge::Seq::Cons[
            head,
            *tail.map {|f| compile(ns, lexicals, f)},
            *(block ? [Rouge::Symbol[:|],
                       block]
                    : [])]
        end
      end
    else
      form
    end
  end
end

# vim: set sw=2 et cc=80:
