# InputBind (DragonRuby 2.26+)
Lets you make input things! Idk how else to describe it...
```rb
def boot args
  args.state.inpt = InputBind.new args do
    bind :jump,         [:|, :space, [:c1d, :a]]
    bind :left_right,   [:left_right], :inp { |v| v == 0 ? nil : v }
    bind :stomp,        [:|, :s, :down, :j, [:c1d, :x], [:c1d, :down]]
    
    group {
      bind_or :apple,  [:i], :kh
      bind_or :banana, [:o], :kh
      bind_or :carrot, [:p], :kh
    }

    group :text_2 {
      bind_or :one,    [:t], :kh
      bind_or :two,    [:y], :kh
      bind_or :three,  [:u], :kh
    }
  end
end

def tick args
  inpt = args.state.inpt
  inpt.tick args
  
  puts "JUMP" if inpt.jump
  puts "TEXT_2" if inpt.group? :text_2

  # etc.
end
```
Checkout/run [main.rb](app/main.rb) for the actual working example and descriptions
