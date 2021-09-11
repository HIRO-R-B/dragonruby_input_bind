# InputBind (DragonRuby 2.26+)
Lets you make input things! Idk how else to describe it...
```rb
def boot args
  args.state.inpt = InputBind.new args do
    bind :jump,         [:space]
    bind :left_right,   [:left_right], :kb { |v| v == 0 ? nil : v }
    bind :stomp,        [:|, :s, :down, :j] # (:|) The 'or' op. Any one of these keys will stomp!
    bind :rocket,       [:|, :k, :space], :kh { |v| v && v.elapsed?(0.4.seconds) }
    bind :good_morning, [:q, :e, :space], :kh # Keep in mind, [:space, :q, :e] would break, since you have an action bound to space
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
Checkout/run [main.rb](app/main.rb) for a better working example
