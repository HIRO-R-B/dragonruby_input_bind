##
# Input handling made easier! Maybe
class InputBind
  attr_accessor :groups, :groups_or, :or_seqs, :binds, :blocks

  def initialize args, file: nil, &block
    assign args

    @group     = 0
    @groups    = {}
    @groups_or = {}

    @or_seqs = []
    @binds   = {}
    @blocks  = {}
    @values  = {}

    @src_table = {
      inp: true, # inputs
      kd:  true, # key_down
      kh:  true, # key_held
      ku:  true, # key_up
      kb:  true, # keyboard
      ms:  true, # mouse
      c1:  true, # controller one
      c1d: true, # controller_one.key_down
      c1h: true, # controller_one.key_held
      c1u: true, # controller_one.key_up
      c2:  true, # controller_two
      c2d: true, # controller_two.key_down
      c2h: true, # controller_two.key_held
      c2u: true  # controller_two.key_up
    }

    @src_lookup = {
      seq: -> key { check_seq key },
      inp: -> key { @inp.send key },
      kd:  -> key { @kd.send key },
      kh:  -> key { @kh.send key },
      ku:  -> key { @ku.send key },
      kb:  -> key { @kb.send key },
      ms:  -> key { @ms.send key },
      c1:  -> key { @c1.send key },
      c1d: -> key { @c1d.send key },
      c1h: -> key { @c1h.send key },
      c1u: -> key { @c1u.send key },
      c2:  -> key { @c2.send key },
      c2d: -> key { @c2d.send key },
      c2h: -> key { @c2h.send key },
      c2u: -> key { @c2u.send key }
    }

    # Use the binds in the file if there even is a file
    #   Defaults to the block otherwise :)
    if file
      binds = $gtk.read_file file
      if binds
        self.instance_eval binds
        return self
      end
    end

    self.instance_eval &block if block
    self
  end

  def tick args
    assign args
    @values = {}

    @groups.each { |_, tree| check tree }
    @groups_or.each { |_, tree| check_or tree }
  end

  def assign args
    @args = args
    @inp  = args.inputs
    @kb   = @inp.keyboard
    @kd   = @kb.key_down
    @kh   = @kb.key_held
    @ku   = @kb.key_up
    @ms   = @inp.mouse
    @c1   = @inp.controller_one
    @c2   = @inp.controller_two
    @c1d  = @c1.key_down
    @c1h  = @c1.key_held
    @c1u  = @c1.key_up
    @c2d  = @c2.key_down
    @c2h  = @c2.key_held
    @c2u  = @c2.key_up
  end

  def input src, key
    @src_lookup[src].call key
  end

  def check_seq key
    @or_seqs[key].each do |s, k|
      val = input s, k
      return val if val
    end

    nil
  end

  def check tree
    tree.each do |(src, key), cdr|
      val = input src, key
      if cdr.is_a?(Array)
        cdr.each do |name|
          block = @blocks[name]
          @values[name] = block ? (block.call val) : val
        end
        next
      end
      val && (check cdr)
    end
  end

  def check_or tree
    tree.each do |(src, key), cdr|
      val = input src, key
      next if !val
      if cdr.is_a?(Array)
        cdr.each do |name|
          block = @blocks[name]
          @values[name] = block ? (block.call val) : val
        end
        break
      end
      ((check_or cdr) && break)
    end

    true
  end

  def seq? tok
    tok == (:|) || tok == (:&)
  end

  def src? tok
    @src_table[tok]
  end

  def valid_seq? tok
    (seq? tok[0]) || (seq? tok[1])
  end

  #               tree, or_seqs, name, binds
  def insert_tree tree, or_seqs, name, (head, *tail)
    raise "#{__method__}: improper bind #{[head, *tail]}" unless seq? head
    last = tail.length - 1
    tail.each_with_index do |bind, idx|
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
      else
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

  def group &block
    @group += 1
    raise "no block supplied" unless block
    block.call
  end

  def bind name, binds, default = :kd, &block
    @binds[name] = binds
    @blocks[name] = block
    @groups[@group] ||= {}
    insert_tree @groups[@group], @or_seqs, name, (parse_binds binds, default)
    define_singleton_method(name) { @values[name] }
  end

  def bind_or name, binds, default = :kd, &block
    @binds[name] = binds
    @blocks[name] = block
    @groups_or[@group] ||= {}
    insert_tree @groups_or[@group], @or_seqs, name, (parse_binds binds, default)
    define_singleton_method(name) { @values[name] }
  end
end

test = true
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

assert.call :parse_bind_4,
            (inpt.parse_binds [:|, :k, :space, [:c1h, :a], [:c1h, :r1]], :kh),
            [:&, [:|, [:kh, :k], [:kh, :space], [:c1h, :a], [:c1h, :r1]]]

tree = {}
inpt.insert_tree tree, inpt.or_seqs, :jump, (inpt.parse_binds [:w, :space], :kh)
assert.call :insert_tree_2,
            tree,
            {[:kh, :w]=>{[:kh, :space]=>[:jump]}}

assert.call :insert_tree_2_or_seq,
            inpt.or_seqs,
            []

inpt.insert_tree tree, inpt.or_seqs, :or_man, (inpt.parse_binds [:|, :a, :b], :kd)
assert.call :insert_tree_2,
            tree,
            {[:kh, :w]=>{[:kh, :space]=>[:jump]}, [:seq, 0]=>[:or_man]}

assert.call :insert_tree_2_or_seq,
            inpt.or_seqs,
            [[[:kd, :a], [:kd, :b]]]

inpt.insert_tree tree, inpt.or_seqs, :haaah, (inpt.parse_binds [[:kh, :|, :shift, :n], [:|, :space, :z]], :kd)
assert.call :insert_tree_3,
            tree,
            {[:kh, :w]=>{[:kh, :space]=>[:jump]}, [:seq, 0]=>[:or_man], [:seq, 1]=>{[:seq, 2]=>[:haaah]}}

assert.call :insert_tree_3_or_seq,
            inpt.or_seqs,
            [[[:kd, :a], [:kd, :b]], [[:kh, :shift], [:kh, :n]], [[:kd, :space], [:kd, :z]]]
