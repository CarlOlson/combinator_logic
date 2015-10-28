
-- a comment

-- S, K, I, B, B', and W combinators are implemented

-- assignment can be done to capital letters
F = KI

S = K = I -- valid, but no effect on other lines

-- lower case is used for unbound variables

"strings are printed
"

"printing terms is easy too: "
print Fxy

"reduce a term: Fxy = "
print reduce Fxy

"reduce* shows steps:
"
print reduce* Fxy

-- check out the command line options with "ruby cl.rb --help"
