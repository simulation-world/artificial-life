; ====================================== ;
;       ARTIFICIAL LIFE - MAIN SIM       ;
; ====================================== ;
; AUTHOR: Charlie Wang
; https://github.com/simulation-world
; -------------------------------------- ;

;============================== SETUP ===============================
;↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓
extensions [ls stats]

globals [
  input-list-strings
  output-list-strings

  max-speed
  max-health
  max-energy
  reproduction-energy
  vision-depth
  vision-fov
]

breed [bugs bug]
breed [plants plant]

plants-own [
  plant-energy
]

bugs-own [
  ;BRAIN ------------------
  brain
  innovation-list-copy
  total-io-nodes-copy
  total-nodes-copy

  ;inputs
  current-health
  current-energy
  current-speed
  food-distance
  food-angle
  food-in-view ;not really an input
  bugs-distance
  bugs-angle
  bugs-in-view ;not really an input

  ;outputs - keep updated with string lists!
  move-fwd
  turn-left
  turn-right
  move-back
  eat-desire
  reproduce-desire
  rest-desire

  brain-inputs
  brain-outputs
  trait-list
  parent-id

  ;GENES ------------------
  ;g-speed-ratio
  ;g-health-ratio
  ;g-size-ratio
  metabolic-cost
  g-max-speed
  g-max-health
  g-max-energy
  g-size-factor
  g-incube-time
  g-hatch-time
  g-reproduction-energy-factor
  g-vision-factor
  g-fov-factor
]

to spawn-plants [amount]
  create-plants amount [
    set color green
    set shape "petals"
    set size ((random 8) + 3) / 10
    set plant-energy 10 * size
    set xcor random-xcor
    set ycor random-ycor
  ]
end

to set-default-bug-traits
  ;setting the names of the input/outputs here will set it in both the main sim and child brain models
  ;meaning these two lines below are IMPORTANT to keep updated
  set input-list-strings (list "health" "energy" "body-size" "food-angle" "food-distance" "bugs-angle" "bugs-distance")
  set output-list-strings (list "move-fwd" "turn-left" "turn-right" "move-back" "eat" "reproduce" "rest")
  set-default-shape bugs "microbe"
  set max-speed 0.1
  set max-health 100
  set max-energy 100
  set reproduction-energy 50
  set vision-depth 3
  set vision-fov 90
end

to setup
  clear-all
  ls:reset
  reset-ticks
  set-default-bug-traits
  spawn-bugs initial-pop; TEMP
  spawn-plants 50
end

;↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑
;============================== MODEL SETUP ===============================



;============================== RUNNING ===============================
;↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓
to go
  ask bugs [live]
  if random plant-growth-rate = 1 [spawn-plants 1]
  tick
end
;↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑
;============================== RUNNING ===============================




;============ ┌─┐┬─┐┌─┐┌─┐┌─┐┌┬┐┬ ┬┬─┐┌─┐┌─┐
;============ ├─┘├┬┘│ ││  ├┤  │││ │├┬┘├┤ └─┐
;============ ┴  ┴└─└─┘└─┘└─┘─┴┘└─┘┴└─└─┘└─┘
;↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓

to spawn-bugs [amount]
  create-bugs amount [
    ;traits/genes --------------- ;in future generations (when hatching bugs) inherit these traits,
    ;should not always use random-float, needs to be by mutation chance
    set g-max-speed max-speed * (precision ((random-float 0.3) - 0.15) 2 + 1) ;range of 0.85 - 1.15
    set g-max-health max-health * (precision ((random-float 0.3) - 0.15) 2 + 1)
    set g-max-energy max-energy * (precision ((random-float 0.3) - 0.15) 2 + 1)
    set g-size-factor (precision ((random-float 0.3) - 0.15) 2 + 1)
    set g-reproduction-energy-factor (precision (random-float 0.3) 2 + 1)
    ;if g-reproduction-energy-factor = 0 [set g-reproduction-energy-factor 1]
    set g-vision-factor vision-depth * (precision ((random-float 0.5) - 0.25) 2 + 1);how far they can see
    set g-fov-factor vision-fov * (precision ((random-float 0.5) - 0.25) 2 + 1);how wide their fov is
    ;set g-incube-time 30
    ;set g-hatch-time 10


    set parent-id "gen 1"

    ;inputs----------------
    set current-health 100
    set current-energy 100
    set current-speed 0
    set food-distance 0

    set brain-inputs (list (current-health) (current-energy) (size) (food-angle)
      (food-distance) (bugs-angle) (bugs-distance)) ;important to keep updated along with the string lists

    set xcor random-xcor
    set ycor random-ycor
    set color white
    set size 1 * g-size-factor

    create-brain
    repeat 5 [attempt-mutate]
  ]
end


to create-brain
  let brain-id 0
  (ls:create-models 1 "neural_brain.nlogo" [[id] -> set brain-id id]) ;create brain and grab its ID
  set brain brain-id
  if who = 0 [ls:show brain] ;TEST

  ls:ask brain [clear-all]
  ls:assign brain test-mode false
  ls:assign brain produce-network false
  ls:assign brain input-list-names input-list-strings
  ls:assign brain output-list-names output-list-strings
  ls:ask brain [setup]
end

to process-brain-inputs
  ;VERY important to KEEP UPDATED along with the string lists
  ;also the order the list is written is VERY IMPORTANT
  set brain-inputs (list (current-health) (current-energy) (size) (food-angle)
      (food-distance) (bugs-angle) (bugs-distance))
  ls:let input-package brain-inputs
  ls:ask brain [process-information input-package]
  set brain-outputs [output-values] ls:of brain

  ;match the outputs variables with their list position
  ;KEEP UPDATED with the string lists!
  set move-fwd item 0 brain-outputs
  set turn-left item 1 brain-outputs
  set turn-right item 2 brain-outputs
  set move-back item 3 brain-outputs
  set eat-desire item 4 brain-outputs
  set reproduce-desire item 5 brain-outputs
  set rest-desire item 6 brain-outputs
end

to see ;INPUT - just food for now, add other organisms later
  set food-in-view plants in-cone g-vision-factor g-fov-factor
  ifelse any? food-in-view [
    set food-angle precision (subtract-headings (heading) (towards (min-one-of food-in-view [distance myself]))) 2
    set food-distance precision (distance (min-one-of food-in-view [distance myself])) 2 ;doing all plants for now, just for testing
  ]
  [
    set food-angle 0
    set food-distance 0
  ]

  set bugs-in-view other bugs in-cone g-vision-factor g-fov-factor
  ifelse any? bugs-in-view [
    if distance min-one-of bugs-in-view [distance myself] != 0 [
      set bugs-angle precision (subtract-headings (heading) (towards (min-one-of bugs-in-view [distance myself]))) 2
    ]
    set bugs-distance precision (distance (min-one-of bugs-in-view [distance myself])) 2 ;doing all plants for now, just for testing
  ]
  [
    set bugs-angle 0
    set bugs-distance 0
  ]
end

to live
  see
  ;------ ↑ procedures feeding inputs should go above this line ↑ ---------
  process-brain-inputs
  ;------ ↓ procedures using outputs should go below this line ↓ ----------
  eat
  move
  reproduce
  manage-energy
  if size < (1 * g-size-factor) [set size size + 0.0001]
end

to move ;OUTPUT
  set current-speed g-max-speed * (move-fwd - move-back)
  let rest-reduction (1 - rest-desire)

  fd current-speed * rest-reduction
  rt -30 * turn-left * rest-reduction
  rt 30 * turn-right * rest-reduction
end

to eat ;OUTPUT
  if any? food-in-view with [distance myself < 1][
    let meal food-in-view with [distance myself < 1]
    set current-energy current-energy + (sum [plant-energy] of meal)
    ask meal [die]
  ]
end

to manage-energy
  ;metabolic cost ↓
  let rest-reduction (1 - rest-desire) + 0.005
  set metabolic-cost precision ((((g-max-speed * size) + (abs(current-speed / 10))) * rest-reduction)) 10
  set current-energy current-energy - metabolic-cost

  if current-energy > 100 [set current-energy 100]
  if current-energy < 0 [set current-energy 0]
  if current-health > 100 [set current-health 100]
  if current-health < 0 [set current-health 0]
  if current-energy >= 100 and current-health < 100 [set current-health current-health + 0.25]
  if current-energy <= 0 [set current-health current-health - 0.25]
  if current-health <= 0 [ls:close brain show "died" die]
end

to reproduce
  if (reproduce-desire > 0.5) and (current-energy > reproduction-energy * g-reproduction-energy-factor) [
    set innovation-list-copy [innovation-list] ls:of brain
    set total-io-nodes-copy [total-io-nodes] ls:of brain
    set total-nodes-copy [count nodes] ls:of brain
    ;let trait-list (list

    hatch-bugs 1 [
      ;inputs----------------
      set current-health 100
      set current-energy 100
      set current-speed 0
      set size 0.5
      set color white
      set food-distance 0

      set brain-inputs (list (current-health) (current-energy) (size) (food-angle)
        (food-distance)) ;update with string list

      ;traits/genes ---------------
      ifelse random-boolean mutation-probability [set g-max-speed [g-max-speed] of myself]
      [set g-max-speed max-speed * (precision ((random-float 0.3) - 0.15) 2 + 1)] ;range of 0.85 - 1.15
      ifelse random-boolean mutation-probability [set g-max-health [g-max-health] of myself]
      [set g-max-health max-health * (precision ((random-float 0.3) - 0.15) 2 + 1)]
      ifelse random-boolean mutation-probability [set g-max-energy [g-max-energy] of myself]
      [set g-max-energy max-energy * (precision ((random-float 0.3) - 0.15) 2 + 1)]
      ifelse random-boolean mutation-probability [set g-size-factor [g-size-factor] of myself]
      [set g-size-factor (precision ((random-float 0.3) - 0.15) 2 + 1)]
      ifelse random-boolean mutation-probability [set g-reproduction-energy-factor [g-reproduction-energy-factor] of myself]
      [set g-reproduction-energy-factor (precision (random-float 0.3) 2 + 1)]
      ifelse random-boolean mutation-probability [set g-vision-factor [g-vision-factor] of myself] ;how far they can see
      [set g-vision-factor vision-depth * (precision ((random-float 0.5) - 0.25) 2 + 1)] ;how far they can see
      ifelse random-boolean mutation-probability [set g-fov-factor [g-fov-factor] of myself] ;how wide their fov is
      [set g-fov-factor vision-fov * (precision ((random-float 0.5) - 0.25) 2 + 1)] ;how wide their fov is
      ;set g-incube-time 30
      ;set g-hatch-time 10

      set parent-id [who] of myself

      ;outputs------------------- ;update with string list
      set brain-outputs (list (move-fwd) (turn-left) (turn-right) (eat-desire) (reproduce-desire) (rest-desire))

      create-brain ;creates new empty brain

      ls:let ls-innovation-list-copy innovation-list-copy
      ls:let ls-total-io-nodes-copy total-io-nodes-copy
      ls:let ls-total-nodes-copy total-nodes-copy

      ls:ask brain [reproduce-brain ;replicate parent brain using the variables defined above
        ls-innovation-list-copy
        ls-total-io-nodes-copy
        ls-total-nodes-copy
      ]
      repeat 5 [attempt-mutate] ;produce mutations in child
      show " was born"
    ]
    set current-energy (current-energy - reproduction-energy * g-reproduction-energy-factor)
  ]
end

to attempt-mutate
  let mutation-chance (random-normal 0 1)
  if mutation-chance <= convert-to-zscore mutation-probability [ ;mutation
    ls:ask brain [mutate random 4 + 1]
  ]
end


;===================== MISC =====================
;↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓

; computes the sigmoid function given an input value and the weight on the link
to-report sigmoid [input]
  report 1 / (1 + e ^ (- input))
end

to-report convert-to-zscore [percent]
  report stats:normal-inverse percent 0 1
end

to-report random-boolean [prob] ;reports true if random chance falls within probability given (standard normal)
  let random-roll (random-normal 0 1)
  ifelse random-roll <= convert-to-zscore prob [report true][report false]
end

to show-brain
  ask bug bug-id [ls:show brain]
end
@#$#@#$#@
GRAPHICS-WINDOW
158
10
772
625
-1
-1
14.8
1
10
1
1
1
0
1
1
1
-20
20
-20
20
0
0
1
ticks
30.0

BUTTON
14
15
77
48
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
82
15
145
48
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

INPUTBOX
34
56
107
116
initial-pop
50.0
1
0
Number

SLIDER
15
123
150
156
mutation-probability
mutation-probability
0
1
0.3
0.1
1
NIL
HORIZONTAL

MONITOR
14
197
88
242
NIL
count bugs
17
1
11

INPUTBOX
14
248
68
308
bug-id
108.0
1
0
Number

BUTTON
71
262
132
295
NIL
show-brain
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
14
312
64
357
energy
[current-energy] of bug bug-id
2
1
11

MONITOR
67
312
117
357
health
[current-health] of bug bug-id
2
1
11

SLIDER
15
160
150
193
plant-growth-rate
plant-growth-rate
10
80
20.0
1
1
NIL
HORIZONTAL

TEXTBOX
118
193
159
236
smaller number\nis faster
11
0.0
1

MONITOR
13
361
90
406
youngest bug
max-one-of bugs [who]
17
1
11

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

https://nn.cs.utexas.edu/downloads/papers/stanley.ec02.pdf
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

egg
false
0
Circle -7500403 true true 96 76 108
Circle -7500403 true true 72 104 156
Polygon -7500403 true true 221 149 195 101 106 99 80 148

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

microbe
true
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 174 39 42
Circle -16777216 true false 84 39 42

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

petals
false
0
Circle -7500403 true true 117 12 66
Circle -7500403 true true 116 221 67
Circle -7500403 true true 41 41 67
Circle -7500403 true true 11 116 67
Circle -7500403 true true 41 191 67
Circle -7500403 true true 191 191 67
Circle -7500403 true true 221 116 67
Circle -7500403 true true 191 41 67
Circle -7500403 true true 60 60 180

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.3.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
