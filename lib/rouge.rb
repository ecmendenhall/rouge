# encoding: utf-8

if RUBY_VERSION < "1.9"
  STDERR.puts "Rouge will probably not run on anything less than Ruby 1.9."
end

module Rouge; end

start = Time.now
Rouge.define_singleton_method :start, lambda {start}

module Rouge
  require 'rouge/version'
  require 'rouge/wrappers'
  require 'rouge/symbol'
  require 'rouge/seq'
  require 'rouge/reader'
  require 'rouge/printer'
  require 'rouge/context'
  require 'rouge/repl'

  def self.print(form, out)
    Rouge::Printer.print form, out
  end

  def self.[](ns)
    Rouge::Namespace[ns]
  end

  def self.boot!
    return if @booted
    @booted = true

    builtin = Rouge[:"rouge.builtin"]

    core = Rouge[:"rouge.core"]
    core.refer builtin

    user = Rouge[:user]
    user.refer builtin
    user.refer core
    user.refer Rouge[:ruby]

    boot_rg = File.read(Rouge.relative_to_lib('boot.rg'))
    Rouge::Context.new(user).readeval(boot_rg)
  end

  def self.repl(options = {})
    boot!
    Rouge::REPL.run!(options)
  end

  def self.relative_to_lib name
    File.join(File.dirname(File.absolute_path(__FILE__)), name)
  end
end

# vim: set sw=2 et cc=80:
