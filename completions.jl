import REPL
open("completions.txt", "w") do io
    join(io, REPL.completion_text.(REPL.completions("", 0)[1]), " ")
end
