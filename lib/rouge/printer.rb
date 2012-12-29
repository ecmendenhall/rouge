# encoding: utf-8
require 'rouge/wrappers'

module Rouge::Printer
  class UnknownFormError < StandardError; end

  def self.print(form, out)
    case form
    when Numeric
      # Handles Integer, Float, Rational, and Complex instances.
      out << form.to_s
    when String, TrueClass, FalseClass, NilClass
      out << form.inspect
    when Array
      out << "[#{print_collection(form)}]"
    when Hash
      out << "{#{print_collection(form)}}"
    when Set
      out << "\#{#{print_collection(form)}}"
    when Regexp
      out << "#\"#{form.source}\""
    when Symbol
      # Symbols containing white space are printed with the results of #inspect,
      # otherwise they are printed with the results #to_s. This maintains an
      # experience consistent with Clojure whenever possible while providing
      # clarity in cases where Symbols contain white space, although this is
      # typically uncommon.
      if /\s/.match(form)
        out << form.inspect
      else
        out << ":#{form}"
      end
    when Rouge::Builtin, Rouge::Symbol, Rouge::Var, Rouge::Seq::Empty, Rouge::Seq::Cons
      out << form.to_s
    when Class, Module
      if form.name
        out << "ruby/#{form.name.split('::').join('.')}"
      else
        out << form.inspect
      end
    else
      out << form.inspect
    end
  end

  # Prints a collection of elements using `print`.
  def self.print_collection(collection)
    if collection.is_a? Hash
      collection.to_a.map {|pair| print_collection(pair) }.join(', ')
    else
      collection.map {|el| print(el, '') }.join(' ')
    end
  end
end

# vim: set sw=2 et cc=80:
