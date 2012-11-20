# encoding: utf-8

class Rouge::Atom
  def initialize(value)
    @value = value
  end

  def ==(var)
    var.object_id == object_id
  end

  def deref
    @value
  end

  def swap! f, *args
    @value = f.call(@value, *args)
  end

  def reset! v
    @value = v
  end
end

# vim: set sw=2 et cc=80:
