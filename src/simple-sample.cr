

def multi(x : Int32, y : Int32)
  x * y
end

def calc(x : Int32, y : Int32, &code : Int32, Int32 -> Float64)
  code.call x, y
end

h = {one: 1, two: 2, three: 3}
pp h

z = multi 3, 6
pp z

v = calc 8, 6 do |x, y|
  x * y * 1.0
end
pp v

msg = "!looc si latsyrc".reverse.capitalize
puts "Result: #{msg}"

