
# I break keyboard support :O
bind :jump,         [:a], :c1d
bind :left_right,   [:left_right], :c1 { |v| v == 0 ? nil : v }
bind :stomp,        [:|, :x, :down], :c1d
bind :rocket,       [:|, :a, :r1], :c1h { |v| v && v.elapsed?(0.4.seconds) }
bind :good_morning, [:l2, :r2, :a], :c1h
bind(:useless,      [:a], :c1d) { |v| v && v.zmod?(15) }

# well, except for these guys
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
