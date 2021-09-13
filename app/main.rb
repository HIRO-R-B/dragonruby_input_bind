require 'input_bind.rb'

# Example bindings and usage!

def boot args
  # Don't actually serialize it...
  #   rename `_input_cfg.rb` to `input_cfg.rb` to see file binds in action
  args.state.inpt = InputBind.new args, file: 'app/input_cfg.rb' do
    bind :jump,         [:|, :space, [:c1d, :a]]
    bind :left_right,   [:left_right], :inp { |v| v == 0 ? nil : v }
    bind :stomp,        [:|, :s, :down, :j, [:c1d, :x], [:c1d, :down]] # (:|) The 'or' op. Any one of these keys will stomp!
    bind :rocket,       [:|, :k, :space, [:c1h, :a], [:c1h, :r1]], :kh { |v| v && v.elapsed?(0.4.seconds) }
    bind :good_morning, [:q, :e, :space], :kh # Keep in mind, [:space, :q, :e] would break, since you have an action bound to space
    bind :good_morning, [:l2, :r2, :a], :c1h # Apparently Multi bindings work, lol
                                             #   Use with caution
    bind(:useless,      [:space]) { |v| v && v.zmod?(15) } # But this is ok though

    # bind_or groups let only one of the bindings at a time be active
    #   with priority being in the order they were binded
    group {
      bind_or :apple,  [:i], :kh
      bind_or :banana, [:o], :kh
      bind_or :carrot, [:p], :kh
    }

    group {
      bind_or :one,    [:t], :kh
      bind_or :two,    [:y], :kh
      bind_or :three,  [:u], :kh
    }
  end
end

def tick args
  state = args.state
  state.x  ||= 0
  state.y  ||= 0
  state.dx ||= 0
  state.dy ||= 0
  state.g  ||= -0.5
  state.stars ||= 20.times.map { [1280.randomize(:int), 720.randomize(:int), 5, 5, 255, 255, 255, 50] }

  inpt = state.inpt
  inpt.tick args

  box_left_right state, inpt.left_right
  box_rocket state if inpt.rocket
  box_stomp  state if inpt.stomp
  box_jump   state if inpt.jump
  box_move   state

  useless_init state if inpt.useless
  stars_move   state if inpt.good_morning

  args.outputs.background_color = [0, 0, 0]
  box_draw      args
  useless_draw  args
  stars_draw    args
  or_binds_draw args, inpt
end

def box_left_right state, left_right
  state.dx = 10 * left_right if left_right
end

def box_rocket state
  state.dy += (-state.g) + 0.1
end

def box_jump state
  state.dy = 10
end

def box_stomp state
  state.dx /= 2
  state.dy = -20
end

def box_move state
  state.px = state.x
  state.py = state.y

  state.dx = state.dx.towards(0, 0.1)
  state.dy += state.g

  state.x += state.dx
  state.x = state.x.clamp(0, 1200)
  state.y += state.dy
  state.y = state.y.clamp(0, 640)
  state.dy = 0 if state.y == 0
end

def box_draw args
  args.outputs.solids << [args.state.px, args.state.py, 80, 80, 255]
  args.outputs.solids << [args.state.x, args.state.y, 80, 80, 255, 255, 255]
end

def useless_init state
  state.useless_a ||= 255
end

def useless_draw args
  state = args.state
  return unless state.useless_a
  state.useless_a = state.useless_a.towards(0, 5)
  args.outputs.labels << {x: 640, y: 360, text: 'USELESS', r: 255, g: 255, b: 255, a: state.useless_a,
                          size_enum: 128,
                          alignment_enum: 1, vertical_alignment_enum: 1 }
  state.useless_a = nil if state.useless_a == 0
end

def stars_move state
  state.stars.each do |star|
    star.y -= 10
    star.y = star.y.clamp_wrap(-5, 720)
  end
end

def stars_draw args
  args.outputs.solids << args.state.stars
end

def or_binds_draw args, inpt
  args.outputs.labels << [0, 720, " apple: #{inpt.apple}", 255, 0, 0]
  args.outputs.labels << [0, 700, "banana: #{inpt.banana}", 255, 0, 0]
  args.outputs.labels << [0, 680, "carrot: #{inpt.carrot}", 255, 0, 0]
  args.outputs.labels << [0, 660, "   one: #{inpt.one}", 255, 0, 0]
  args.outputs.labels << [0, 640, "   two: #{inpt.two}", 255, 0, 0]
  args.outputs.labels << [0, 620, " three: #{inpt.three}", 255, 0, 0]
end
