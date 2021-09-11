## Input handling made easier! Maybe
#
class InputBind
  attr_accessor :tree, :tree_or, :or_seqs, :binds, :block

  def initialize args, &block
    assign args
    @tree    = {}
    @tree_or = {}
    @or_seqs = []
    @binds   = {}
    @block   = {}
    @values  = {}

    self.instance_eval &block if block
    self
  end

  def tick args
    assign args
    @values = {}

    check @tree
    check @tree_or
  end

  def assign args
    @args = args
    @inp = args.inputs
    @kb  = @inp.keyboard
    @kd  = @kb.key_down
    @kh  = @kb.key_held
    @ku  = @kb.key_up
    @ms  = @inp.mouse
    @c1  = @inp.controller_one
    @c2  = @inp.controller_two
    @c1d = @c1.key_down
    @c1h = @c1.key_held
    @c1u = @c1.key_up
    @c2d = @c2.key_down
    @c2h = @c2.key_held
    @c2u = @c2.key_up
  end

  def input src, key
    if    src == :seq
      @or_seqs[key].each do |s, k|
        val = input s, k
        return val if val
      end

      nil
    elsif src == :inp
      @inp.send key
    elsif src == :kd
      @kd.send key
    elsif src == :kh
      @kh.send key
    elsif src == :ku
      @ku.send key
    elsif src == :kb
      @kb.send key
    elsif src == :ms
      @ms.send key
    elsif src == :c1
      @c1.send key
    elsif src == :c1d
      @c1d.send key
    elsif src == :c1h
      @c1h.send key
    elsif src == :c1u
      @c1u.send key
    elsif src == :c2
      @c2.send key
    elsif src == :c2d
      @c2d.send key
    elsif src == :c2h
      @c2h.send key
    elsif src == :c2u
      @c2u.send key
    end
  end

  def check tree
    tree.each do |(src, key), cdr|
      val = input src, key
      cdr.is_a?(Array) && cdr.each do |name|
        block = @block[name]
        @values[name] = block ? (block.call val) : val
      end
      val && (check cdr)
    end
  end

  def check_or tree
    tree.each do |(src, key), cdr|
      val = input src, key
      next if !val
      (check_only cdr) && break if !cdr.is_a?(Array)
      break cdr.each do |name|
        block = @block[name]
        @values[name] = block ? (block.call val) : val
      end
    end
  end

  def insert_tree tree, or_seqs, name, binds
    if seq? binds[0]
      binds.shift

      last = binds.length - 1
      binds.each_with_index do |bind, idx|
        if (:|) == bind[0]
          bind.shift
          or_seqs << bind
          bind = [:seq, or_seqs.length - 1]
        end

        if idx == last
          tree[bind] ||= []
          tree[bind] << name
        else
          tree[bind] ||= {}
          tree = tree[bind]
        end
      end
    end
  end

  def seq? tok
    tok == (:|) || tok == (:&)
  end

  def src? tok
    ( tok == :inp || # inputs
      tok == :kd  || # key_down
      tok == :kh  || # key_held
      tok == :ku  || # key_up
      tok == :kb  || # keyboard
      tok == :ms  || # mouse
      tok == :c1  || # controller one
      tok == :c1d || # controller_one.key_down
      tok == :c1h || # controller_one.key_held
      tok == :c1u || # controller_one.key_up
      tok == :c2  || # controller_two
      tok == :c2d || # controller_two.key_down
      tok == :c2h || # controller_two.key_held
      tok == :c2u )  # controller_two.key_up
  end

  def valid_seq? tok
    (seq? tok[0]) || (seq? tok[1])
  end

  def parse_seq bind, default
    bind.map do |tok|
      if src? tok
        default = tok
        next
      end
      next tok if seq? tok
      case tok
      when Array
        next parse_seq tok, default if valid_seq? tok

        tok
      when Symbol
        [default, tok]
      end
    end.compact
  end

  def parse_binds binds, default
    binds = parse_seq binds, default
    binds.unshift (:&) if !(seq? binds[0])
    binds = [:&, binds] if !(:& == binds[0])
    binds
  end

  def bind name, binds, default = :kd, tree: @tree, &block
    @binds[name] = binds
    @block[name] = block

    insert_tree tree, @or_seqs, name, (parse_binds binds, default)
    define_singleton_method(name) { @values[name] }
  end

  def bind_or name, binds, default = :kd, &block
    bind name, binds, default, tree: @tree_or, &block
  end
end

test = false
return unless test
assert = -> name, a, b { raise "#{name} failed\na: #{a}\nb: #{b}" if a != b }
inpt = InputBind.new $args

assert.call :parse_bind_1,
            (inpt.parse_binds [:w, :space], :kh),
            [:&, [:kh, :w], [:kh, :space]]

assert.call :parse_bind_2,
            (inpt.parse_binds [:|, :a, :b], :kd),
            [:&, [:|, [:kd, :a], [:kd, :b]]]

assert.call :parse_bind_3,
            (inpt.parse_binds [[:kh, :|, :shift, :n], [:|, :space, :z]], :kd),
            [:&, [:|, [:kh, :shift], [:kh, :n]], [:|, [:kd, :space], [:kd, :z]]]

inpt.insert_tree inpt.tree, inpt.or_seqs, :jump, (inpt.parse_binds [:w, :space], :kh)
assert.call :insert_tree_2,
            inpt.tree,
            {[:kh, :w]=>{[:kh, :space]=>[:jump]}}

assert.call :insert_tree_2_or_seq,
            inpt.or_seqs,
            []

inpt.insert_tree inpt.tree, inpt.or_seqs, :or_man, (inpt.parse_binds [:|, :a, :b], :kd)
assert.call :insert_tree_2,
            inpt.tree,
            {[:kh, :w]=>{[:kh, :space]=>[:jump]}, [:seq, 0]=>[:or_man]}

assert.call :insert_tree_2_or_seq,
            inpt.or_seqs,
            [[[:kd, :a], [:kd, :b]]]

inpt.insert_tree inpt.tree, inpt.or_seqs, :haaah, (inpt.parse_binds [[:kh, :|, :shift, :n], [:|, :space, :z]], :kd)
assert.call :insert_tree_3,
            inpt.tree,
            {[:kh, :w]=>{[:kh, :space]=>[:jump]}, [:seq, 0]=>[:or_man], [:seq, 1]=>{[:seq, 2]=>[:haaah]}}

assert.call :insert_tree_3_or_seq,
            inpt.or_seqs,
            [[[:kd, :a], [:kd, :b]], [[:kh, :shift], [:kh, :n]], [[:kd, :space], [:kd, :z]]]
