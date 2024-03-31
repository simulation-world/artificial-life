; ========================================== ;
;       ARTIFICIAL LIFE - NEURAL BRAIN       ;
; ========================================== ;
; AUTHOR: Charlie Wang
; https://github.com/simulation-world
; ------------------------------------------ ;

;============================== SETUP ===============================
;↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓
extensions [ls]

globals [
  innovation-list ;list of all connections pairs established ever
  innovation-counter ;keeps count of total innovation numbers

  input-nodes ;the actual neural nodes
  output-nodes
  non-input-nodes ;all nodes that are not inputs
  non-output-nodes ;all nodes that are not outputs
  total-io-nodes ;total count of input/output nodes

  input-list-names ;string lists of inputs and outputs
  output-list-names

  output-values ;actual number values to drive behavior

  neuron-field ;area where new neurons can be formed
  input-neuron-line ;pxcor of patches reserved for input neurons
  output-neuron-line ;pxcor of patches reserved for output neruons

  function-list ;list of all possible functions for neurons
]

breed [nodes node]

nodes-own [
  ID ;string of what the node is for
  value ;numerical value
  function ;for intermediate neurons that have a function
  order ;order in the neuron tree (i.e. the input nodes are 0, next layer will be 1, then 2.. etc.)
  node-enabled ;binary toggle
]

links-own [
  weight
  innovation-number
  calculated-link-data ;weight * source node value
  link-enabled ;binary toggle
]



to form-base-nodes [lst xcord]
  let increment world-height / length lst
  let cor min-pycor + (increment / 2)
  let index 0

  repeat length lst [
    create-nodes 1 [
      set shape "circle"
      set color red

      set xcor xcord
      set ycor cor

      if test-mode [set value 1] ;TEST
      set ID item index lst
      set label value
      show (word "index: " index ", ID: " ID)
      set node-enabled 1

      set total-io-nodes total-io-nodes + 1

    ]
    ;nicer labels not attached to the nodes directly
    ask patch (xcord + round ((length (item index lst)) / 10)) ((round cor) + 1) [set plabel (word item index lst)]

    set cor cor + increment
    set index index + 1
  ]
end

to setup-brain
  if test-mode [
    set input-list-names (list "health" "energy" "body-size" "food-angle" "food-distance" "bug-angle" "bug-distance")
    set output-list-names (list "move-fwd" "turn-left" "turn-right" "move-back" "eat" "reproduce" "rest")
  ]

  form-base-nodes input-list-names min-pxcor + 1
  form-base-nodes output-list-names max-pxcor - 1

  set input-nodes nodes with [xcor = min-pxcor + 1]
  set output-nodes nodes with [xcor = max-pxcor - 1]

  ;TEST TEST TEST
  ask input-nodes [
    create-link-to one-of output-nodes with [my-in-links = no-links] [
      set weight (((random 40 + 1) - 20) / 10)
      set label weight
      set link-enabled 1
      set color blue
      add-to-innovation-list
      ;innovation list will be formatted as:
      ;[source node, destination node, link weight, link enabled?]
    ]
  ]
end

to setup
  if test-mode [clear-all]
  reset-ticks
  set innovation-list []
  set function-list (list "sig" "lin" "sqr" "sin" "abs")
  setup-brain

  ;defines physical locations and agentsets/node groups within the brain
  set input-neuron-line min-pxcor + 1
  set output-neuron-line max-pxcor - 1
  set neuron-field patches with [(pxcor > input-neuron-line + 1) and (pxcor < output-neuron-line - 1)]
  set non-input-nodes nodes with [xcor != input-neuron-line]
  show non-input-nodes
  set non-output-nodes nodes with [xcor != output-neuron-line]

  if produce-network [
    repeat 5 [mutate 1] ;TEST
    repeat 2 [mutate 2] ;TEST
  ]
end
;↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑
;============================== SETUP ===============================




;============ ┌─┐┬─┐┌─┐┌─┐┌─┐┌┬┐┬ ┬┬─┐┌─┐┌─┐
;============ ├─┘├┬┘│ ││  ├┤  │││ │├┬┘├┤ └─┐
;============ ┴  ┴└─└─┘└─┘└─┘─┴┘└─┘┴└─└─┘└─┘
;↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓


to-report write-output-nodes [output-vals] ;takes list of output vals as argument
  report output-vals
end

;=============================== PROCESSING ==============================
;↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓
to process-information [input-vals]
  ;read input nodes -------------------------------------
  ;carefully [
    let index 0
    repeat length input-vals [
      ask node index [(set value item index input-vals) (set label value)]
      set index index + 1
    ]
    ; --------------------------------------------------------

    ask input-nodes [
      set color green
      ask my-out-links with [link-enabled = 1] [(set calculated-link-data precision ([value] of myself * weight) 2) (set label (word "W:" weight ", C: " calculated-link-data))]
      ;↑ first calculate the node * link values of the input nodes (single step) ↑
      let next-neighbors out-link-neighbors with [node-enabled = 1];create agentset of the out-link neighbors of the input nodes

      while [next-neighbors != no-turtles] [ ;while the current neighbors exist
        ask next-neighbors [ ;ask the current group of neighbors
          set color green

          set value precision (sum ([calculated-link-data] of (my-in-links with [link-enabled = 1]))) 2 ;calculate the sum of your in-links (vals already calculated at step above) and set it to your current value
          if function != 0 [set value (modify-with-function function value)] ;modify the summed value with the node's function
          ask my-out-links with [link-enabled = 1] [(set calculated-link-data precision ([value] of myself * weight) 2) (set label (word "W:" weight ", C: " calculated-link-data))] ;ask your out-links to calculate their node * link values

          ifelse member? self output-nodes [
            let sig precision (sigmoid value) 3 ;output nodes must convert values into a sigmoid output between 0 and 1
            set label (word value ", SIG: " sig)
          ]
          [set label (word value " " function)] ;regular nodes just show their value & function
                            ;show (Word "next-neighbors: " next-neighbors ", " self) ;TEST
          set next-neighbors out-link-neighbors with [node-enabled = 1] ;update the group of neighbors to the next neighbors
        ]
      ]
    ]
    let output-vals []
    ;if an output-node has no in links, just set the output to zero (otherwise sigmoid function will produce 0.5)
    foreach sort-on [who] output-nodes [x ->
      ifelse [my-in-links] of x != no-links [set output-vals lput precision (sigmoid ([value] of x)) 2 output-vals]
      [set output-vals lput 0 output-vals]
    ]
    set output-values output-vals
    ;show (word "output-values: " output-values ", output-vals: " output-vals) ;TEST
  ;]
  ;[show error-message]
end
;↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑
;=============================== PROCESSING ==============================


;=============================== MUTATION ==============================
;↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓
to mutate [m-type]
  ;set m-type 1 ;(random 5) + 1
  if count links = 0 [set m-type 1]

  if m-type = 1 [ ;form link/synapse between neurons *MAY NOT GET NEW INNOV. NUM)
    let in one-of non-output-nodes with [(count my-out-links) < (count non-input-nodes)] ;choose input node that a does not have a connection to every output node
    let out one-of non-input-nodes with [((in-link-from in) = nobody) and (who != [who] of in)]
    ;show (word "in: " in ", out: " out) ;TEST
    ask in [
      create-link-to out [
        set weight (((random 40 + 1) - 20) / 10)
        set label weight
        set link-enabled 1
        set color blue
        add-to-innovation-list
        ;innovation list will be formatted as: [source node, destination node, link weight, link enabled?, destination node function]
      ]
    ]
  ]
  if m-type = 2 [ ;form new neuron/node on existing link (i.e. split a connection with a node) (old link keeps same value, new link has value of 1) *GETS NEW INNOV. NUM*
    let old-link one-of links
    let innov-list-entry (list ([who] of [end1] of old-link) ([who] of [end2] of old-link) ([weight] of old-link) ([link-enabled] of old-link))
    ;↑↑↑ keep updated with add-to-innovation-list function ↑↑↑

    create-nodes 1 [
      set shape "circle"
      set color white
      set id "mutated"
      set node-enabled 1
      set function one-of function-list
      set label function
      set label-color blue

      set xcor ([xcor] of ([end1] of old-link) + [xcor] of ([end2] of old-link)) / 2
      set ycor ([ycor] of ([end1] of old-link) + [ycor] of ([end2] of old-link)) / 2
      create-link-from [end1] of old-link [(set weight 1) (set label weight) (set link-enabled 1) (set color blue)]
      create-link-to [end2] of old-link [(set weight [weight] of old-link) (set label weight) (set link-enabled 1) (set color blue)]

      ;remove innovation list entry of the old connection the node is splitting
      foreach innovation-list [entry -> if entry = innov-list-entry [
        show entry
        set innovation-list remove entry innovation-list
        ]
      ]

      ;create new innovation list entries of the two new connections
      ask my-in-links [add-to-innovation-list]
      ask my-out-links [add-to-innovation-list]

      ask old-link [die]
      set non-input-nodes nodes with [xcor != input-neuron-line]
      set non-output-nodes nodes with [xcor != output-neuron-line]
    ]
  ]
  if m-type = 3 [ ;enable or disable connection/synapse
    ask one-of links [
      ifelse link-enabled = 1 [set link-enabled 0 set color gray][set link-enabled 1 set color blue]
      update-innovation-list
    ]
  ]
  if m-type = 4 [ ;mutate weight by shifting by some factor
    ask one-of links [ ;may need to filter to only links that are enabled
      (set weight weight * precision (random-float 2) 2)
      set label weight
      update-innovation-list
    ]
  ]
  if m-type = 5 [ ;mutate weight by forming a completely new weight between -2 and 2
    ask one-of links [ ;may need to filter to only links that are enabled
      (set weight precision ((random-float 4) - 2) 2)
      set label weight
      update-innovation-list
    ]
  ]
  if m-type = 6 [ ;destroy synapse or neuron

  ]
end
;↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑
;=============================== MUTATION ==========================


to-report innovation-list-entry ;to be run by a link, to format its properties as a innovation list entry
  report (list ([who] of end1) ([who] of end2) (weight) (link-enabled) ([function] of end2))
  ;innovation list will be formatted as: [source node, destination node, link weight, link enabled?, destination node function]
end

to add-to-innovation-list ;to be run by a link, to add its innovation list entry to the list
  set innovation-list lput innovation-list-entry innovation-list
end

to update-innovation-list ;to be run by a link, when editing a value of the link properties in the list
  foreach innovation-list [entry -> if (item 0 entry = [who] of end1) and (item 1 entry = [who] of end2)[
    set innovation-list replace-item (position entry innovation-list) innovation-list innovation-list-entry
    ]
  ]
end

;example call: reproduce-brain innovation-list-copy total-io-nodes-copy total-nodes-copy
to reproduce-brain [i-list io-nodes total-nodes] ;takes innovation list as input, count of io nodes and total nodes
  let source 0
  let dest 0
  let non-io-nodes (total-nodes - io-nodes) ;define a few variables

  repeat non-io-nodes [ ;create the mutated nodes (non input/output nodes)
    create-nodes 1 [
      set shape "circle"
      set color white
      set id "mutated"
      set node-enabled 1
      set label value
      set xcor [pxcor] of one-of neuron-field
      set ycor [pycor] of one-of neuron-field
    ]
  ]

  foreach i-list [entry ->  ;create the links between nodes
    if any? nodes with [who = item 0 entry][set source node (item 0 entry)] ;set source node from innov.list
    if any? nodes with [who = item 1 entry][set dest node (item 1 entry)] ;set dest node from innov.list
    ask source [create-link-to dest [ ;create link between source and destination, apply the weight and toggle-boolean
      set weight item 2 entry
      set link-enabled item 3 entry
      set label weight
      ifelse link-enabled = 1 [set color blue][set color gray]
      ask end2 [(set function item 4 entry) (set label-color blue) (set label function)]
      ]
    ]
  ]
end

;↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑
;===================== MUTATION =====================


;===================== MISC =====================
;↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓

; computes the sigmoid function given an input value and the weight on the link
to-report sigmoid [input]
  report 1 / (1 + e ^ (- input))
end

to-report modify-with-function [func val]
  if func = "sig" [report 1 / (1 + e ^ (- val))]
  if func = "lin" [report val]
  if func = "sqr" [report val * 2] ;not squaring for now because i guess it makes a number too big for nlogo
  if func = "sin" [report sin(val)]
  if func = "abs" [report abs(val)]
end
@#$#@#$#@
GRAPHICS-WINDOW
205
10
790
596
-1
-1
17.5
1
10
1
1
1
0
0
0
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
44
34
107
67
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

SWITCH
25
75
137
108
test-mode
test-mode
0
1
-1000

SWITCH
12
114
162
147
produce-network
produce-network
1
1
-1000

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
