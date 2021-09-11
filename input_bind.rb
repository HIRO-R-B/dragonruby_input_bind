## Input handling made easier! Maybe
#
class InputBind
  attr_accessor :tree, :tree_or, :or_seqs

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
    @inputs = args.inputs
    @kb = @inputs.keyboard
    @kd = @kb.key_down
    @kh = @kb.key_held
    @ku = @kb.key_up
    @ms = @inputs.mouse
  end

  def input src, key
    if    src == :seq
      @or_seqs[key].each do |s, k|
        val = input s, k
        return val if val
      end

      nil
    elsif src == :kd
      @kd.send key
    elsif src == :kh
      @kh.send key
    elsif src == :ku
      @ku.send key
    elsif src == :ms
      @ms.send key
    elsif src == :kb
      @kb.send key
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
    ( tok == :kd || # key_down
      tok == :kh || # key_held
      tok == :ku || # key_up
      tok == :ms || # mouse
      tok == :c1 || # controller 1
      tok == :c2 || # controller 2
      tok == :kb )  # keyboard
  end

  def parse_binds binds, default, depth = 0
    case binds
    when Array
      binds = binds.map do |bind|
        if src? bind
          default = bind
          next
        end
        parse_binds bind, default, depth + 1
      end.compact
      binds.unshift (:&) if !(seq? binds[0])
      binds = [:&, binds] if depth == 0 && !(:& == binds[0])
      binds
    when -> tok { seq? tok }
      binds
    else
      [default, binds]
    end
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
