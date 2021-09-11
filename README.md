# InputBind (DragonRuby 2.26+)
Lets you make input things! Idk how else to describe it...
```rb
def boot args
  args.state.inpt = InputBind.new args do
    bind :jump,         [:|, :space, [:c1d, :a]]
    bind :left_right,   [:left_right], :inp { |v| v == 0 ? nil : v }
    bind :stomp,        [:|, :s, :down, :j, [:c1d, :x], [:c1d, :down]] # (:|) The 'or' op. Any one of these keys will stomp!
    bind :rocket,       [:|, :k, :space, [:c1h, :a], [:c1h, :r1]], :kh { |v| v && v.elapsed?(0.4.seconds) }
    bind :good_morning, [:q, :e, :space], :kh # Keep in mind, [:space, :q, :e] would break, since you have an action bound to space
    bind :good_morning, [:l2, :r2, :a], :c1h # Apparently Multi bindings work, lol
                                             #   Use with caution
    bind(:useless,      [:space]) { |v| v && v.zmod?(15) } # But this is ok though
  end
end

def tick args
  inpt = args.state.inpt
  inpt.tick args
  
  puts "JUMP" if inpt.jump

  # etc.
end

```
Checkout/run [main.rb](app/main.rb) for the actual working example
