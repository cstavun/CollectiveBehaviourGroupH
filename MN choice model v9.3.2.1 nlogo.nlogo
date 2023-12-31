;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Mymecina nipponica nest choice model
;
; Based on the work of Adam L Cronin : v 9.3.2.1 20180620
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; This model is designed to replicate the nest selection and emigration process in the ant Myrmecina nipponica.
; We decided to change the model by adding environment parameters (such as food, protection, predator)
; The goal of the ants is now to not only find a good nest like in the original model, but to find the best one.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;




;;;;;;;;;;;;;;;;;;;;;;;;
;;; variables        ;;;-----------------------------------------------------------------------------------------
;;;;;;;;;;;;;;;;;;;;;;;;


breed [ants ant]
breed [nests nest]

globals
[
  total-brood           ;; total number of brood items, derived from colony size and brood percent
  best-nest             ;; nest with highest available quality score
  success               ;; emigration completed to best available nest (1 or 0)
  result                ;; emigration completed within set time limit (1 or 0)
  first-nest-discovered ;; identity of the first nest discovered
  chosen-nest-discovery ;; time the first ant entered the finally selected nest
  chosen-nest-assessment;; time of discovery of chosen nest until first quorum threshold acheived in chosen nest
  chosen-nest-transport ;; time from first quorum achieved in chosen nest until end of emigration
  first-discovery-time  ;; time the first ant entered any new nest
  nest-chosen           ;; identity of the final nest chosen
  split                 ;; brood transported to more than one nest (1) or only one nest (0)
  nests-found           ;; total number of nests which had at least one visit
  nests-with-votes      ;; total number of nests which had at least one ant accept them
  chosen-votes          ;; total number of time the finally chosen nest was accepted
  other-votes           ;; total number of times all other nests were accepted
  scouts                ;; number of ants which visited at least one new nest
]

patches-own
[
  pheromone            ;; amount of pheromone on this patch
  patch-ID             ;; unique identifier for each patch
]

ants-own
[
  class                ;; current behavioural status
  current-vote         ;; currently favoured patch for relocation (Patch ID)
  accept-threshold     ;; minimum acceptible nest quality
  going-to             ;; direction (nest ID)
  quorum-threshold     ;; individual quorum threshold
  transports           ;; counter
  waiting              ;; current count down to action
  carrying             ;; binary variable for brood transport (1 or 0)
  commitment           ;; influence of private information
  trail-influence      ;; influence of social information
  scout-ant            ;; flag for nest visit
]

nests-own
[
  quality              ;; quality score of nest (0-100)
  quality-class        ;; quality class of nest (good or bad)
  first-in             ;; time first ant visited nest
  first-trans          ;; time first transport arrived at nest
  switchers            ;; number of ants which switched to transport roles at nest (achieved quorum threshold)
  votes                ;; number of times ants accepted the nest
  tq                   ;; time at which first quorum threshold was achieved at the nest
  brood                ;; number of brood at the nest
  food                 ;; if a food source is present next to it
  protection           ;; if the nest is protected
  predator             ;; if a predator is present
]


;;;;;;;;;;;;;;;;;;;;;;;;
;;; main             ;;;-----------------------------------------------------------------------------------------
;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all
  setup-nests
  setup-ants
  setup-patches
  reset-ticks
end

to go
 if ticks >= max-ticks ; halt run if maximum time limit is reached
  [
    set result 0
    set-results
    stop
  ]

 ask ants ; run go procedures for each ant depending on its current class
    [
      ifelse waiting > 0                 ;; wait or act according to class
        [
          if waiting = 1 and class != "nestant" [avoid-double-marking] ;
          set waiting waiting - 1
          let ID [patch-ID] of patch-here
          if ID > 0 and ID < 99 [check-quorum ID]
        ]
        [
          if class = "nestant" [stay-in-nest]
          if class = "scout" [search]
          if class = "decided" [recruit]
          if class = "transporter" [transport]
        ]
    ]
  diffuse pheromone (diffusion-rate)
  ask patches ; update environment
    [
      set pheromone pheromone * (100 - evaporation-rate) / 100  ;; slowly evaporate pheromone
      recolor-patch
    ]

if [brood] of nest 0 = 0 and count ants with [carrying = 1] = 0 ; halt simulation if all brood have been moved
  [
    set-results
    set result 1
    stop
  ]

tick

end


;;;;;;;;;;;;;;;;;;;;;;;;
;;; Setup procedures ;;;-----------------------------------------------------------------------------------------
;;;;;;;;;;;;;;;;;;;;;;;;

to setup-nests
  create-nests number-of-nests + 1 ; add one to number of nests for home nest (nest 0)
   [
     set size nest-size
     set color grey
     set shape "circle"
     set quality 50
     set first-in 0
     set first-trans 0
     set switchers 0
     set votes 0
     set tq 0
     set brood 0
     set quality-class "bad" ; default for all nests
     set food false
     set protection false
     set predator false
   ]

 ;geolocate nests in circle
 let xcor-list [0 0 0 38 -38 28 28 -28 -28 15 -15 35 35 -35 -35 15 -15]
 let ycor-list [0 38 -38 0 0 28 -28 28 -28 35 35 15 -15 -15 15 -35 -35]
 let i 0
  while [i <= number-of-nests]
    [ask nest i [
          set xcor item i xcor-list
          set ycor item i ycor-list
          ; Set the variables food, protection, predator
          ifelse i = 1 [
            set food Nest1Food
            set protection Nest1Protection
            set predator Nest1Predator
          ] [
            ifelse i = 2 [
              set food Nest2Food
              set protection Nest2Protection
              set predator Nest2Predator
            ] [
              ifelse i = 3 [
                set food Nest3Food
                set protection Nest3Protection
                set predator Nest3Predator
              ] [
                ifelse i = 4 [
                  set food Nest4Food
                  set protection Nest4Protection
                  set predator Nest4Predator
                ] [
                  ifelse i = 5 [
                    set food Nest5Food
                    set protection Nest5Protection
                    set predator Nest5Predator
                  ] [
                    ifelse i = 6 [
                      set food Nest6Food
                      set protection Nest6Protection
                      set predator Nest6Predator
                    ] [
                      ifelse i = 7 [
                        set food Nest7Food
                        set protection Nest7Protection
                        set predator Nest7Predator
                      ] [
                        ifelse i = 8 [
                          set food Nest8Food
                          set protection Nest8Protection
                          set predator Nest8Predator
                        ] [
                          ifelse i = 9 [
                            set food Nest9Food
                            set protection Nest9Protection
                            set predator Nest9Predator
                          ] [
                            ifelse i = 10 [
                              set food Nest10Food
                              set protection Nest10Protection
                              set predator Nest10Predator
                            ] [
                              ifelse i = 11 [
                                set food Nest11Food
                                set protection Nest11Protection
                                set predator Nest11Predator
                              ] [
                                ifelse i = 12 [
                                  set food Nest12Food
                                  set protection Nest12Protection
                                  set predator Nest12Predator
                                ] [
                                  ifelse i = 13 [
                                    set food Nest13Food
                                    set protection Nest13Protection
                                    set predator Nest13Predator
                                  ] [
                                    ifelse i = 14 [
                                      set food Nest14Food
                                      set protection Nest14Protection
                                      set predator Nest14Predator
                                    ] [
                                      ifelse i = 15 [
                                        set food Nest15Food
                                        set protection Nest15Protection
                                        set predator Nest15Predator
                                      ] [
                                          set food Nest16Food
                                          set protection Nest16Protection
                                          set predator Nest16Predator
                                      ]
                                    ]
                                  ]
                                ]
                              ]
                            ]
                          ]
                        ]
                      ]
                    ]
                  ]
                ]
              ]
            ]
          ]
          set quality-class "good"
          if food [
            set quality quality + 20
          ]
          if protection [
            set quality quality + 20
          ]
          if predator [
            set quality quality - 30
          ]
        ]
      set i i + 1
    ]

  let new-nests nests with [who > 0] ; create seperate nest set excluding the home nest
  ask nests [ask patches in-radius (nest-size * 1.5) ; create findable area around each nest agent
    [
      set pcolor grey
      set patch-ID [who] of myself
    ]]
  ask nest 0 ; setup home nest
    [
      ask patches in-radius (nest-size * 1.5) [set patch-ID 99] ; set different ID for home nest patches
      set brood floor colony-size * brood-percent / 100
    ]

  let j 1 ;Start at 1 because the nest 0 is the initial nest
  while [j <= number-of-nests]
    [
      ask nest j ; Add the food, protection, predator on the interface
        [
          let circle-xcor xcor
          let circle-ycor ycor

          let number 0
          if food [set number number + 1]
          if protection [set number number + 1]
          if predator [set number number + 1]

          if number = 1 [
            ifelse xcor > 0 [
              set circle-xcor circle-xcor + nest-size + 4
              ifelse ycor > 0 [
                set circle-ycor circle-ycor + nest-size + 4
              ] [
                ifelse ycor < 0
                [set circle-ycor circle-ycor - nest-size - 4]
                [set circle-xcor  circle-xcor + 3]
              ]
            ] [
              ifelse xcor < 0 [
                set circle-xcor  circle-xcor - nest-size - 4
                ifelse ycor > 0 [
                  set circle-ycor  circle-ycor + nest-size + 4
                ] [
                  ifelse ycor < 0 [
                    set circle-ycor  circle-ycor - nest-size - 4
                  ] [
                    set circle-xcor  circle-xcor - 3
                  ]
                ]
              ] [
                ifelse ycor > 0 [
                  set circle-ycor circle-ycor + nest-size + 7
                ] [
                  ifelse ycor < 0 [
                    set circle-ycor circle-ycor - nest-size - 7
                  ] [
                  ]
                ]
              ]
            ]
            hatch 1 [
              ifelse food [
                set shape "square"
                set size 2
                set color violet
                setxy circle-xcor circle-ycor
              ][
              ifelse predator [
                set shape "triangle"
                set size 2
                set color red
                setxy circle-xcor circle-ycor
              ][
                set shape "star"
                set size 2
                set color yellow
                setxy circle-xcor circle-ycor
              ]
              ]
            ]
          ]

          if number = 2 [
            let circle1-xcor 0
            let circle1-ycor 0
            let circle2-xcor 0
            let circle2-ycor 0


            ifelse xcor > 0 [
              ifelse ycor > 0 [
                set circle2-ycor circle-ycor
                set circle1-ycor circle-ycor + nest-size + 4
                set circle1-xcor circle-xcor
                set circle2-xcor circle-xcor + nest-size + 4
              ][ifelse ycor < 0
                [
                set circle1-xcor circle-xcor
                set circle2-xcor circle-xcor + nest-size + 4
                set circle2-ycor circle-ycor
                set circle1-ycor circle-ycor - nest-size - 4
                ][
                set circle1-xcor circle-xcor + nest-size + 3
                set circle2-xcor circle-xcor + nest-size + 3
                set circle2-ycor circle-ycor + nest-size + 3
                set circle1-ycor circle-ycor - nest-size - 3
                ]]]
            [ifelse xcor < 0 [
              ifelse ycor > 0 [
                set circle2-ycor circle-ycor
                set circle1-ycor circle-ycor + nest-size + 4
                set circle1-xcor circle-xcor
                set circle2-xcor circle-xcor - nest-size - 4
              ][ifelse ycor < 0
                [
                set circle1-xcor circle-xcor
                set circle2-xcor circle-xcor - nest-size - 4
                set circle2-ycor circle-ycor
                set circle1-ycor circle-ycor - nest-size - 4
                ][
                set circle1-xcor circle-xcor - nest-size - 3
                set circle2-xcor circle-xcor - nest-size - 3
                set circle2-ycor circle-ycor + nest-size + 3
                set circle1-ycor circle-ycor - nest-size - 3
                ]]
            ][
              ifelse ycor > 0 [
                set circle2-ycor circle-ycor + nest-size + 3
                set circle1-ycor circle-ycor + nest-size + 3
                set circle1-xcor circle-xcor + nest-size + 3
                set circle2-xcor circle-xcor - nest-size - 3
              ]
                [
                set circle1-xcor circle-xcor + nest-size + 3
                set circle2-xcor circle-xcor - nest-size - 3
                set circle2-ycor circle-ycor - nest-size - 3
                set circle1-ycor circle-ycor - nest-size - 3
                ]]
            ]

            let taken1 false
            if predator [
              hatch 1 [
                set taken1 true
                set shape "triangle"
                set size 2
                set color red
                setxy circle1-xcor circle1-ycor
              ]
            ]
            if food [
              hatch 1 [
                set shape "square"
                set size 2
                set color violet
                ifelse taken1 [
                  setxy circle2-xcor circle2-ycor
                ][set taken1 true
                  setxy circle1-xcor circle1-ycor]
              ]
            ]
            if protection [
              hatch 1 [
                set shape "star"
                set size 2
                set color yellow
                setxy circle2-xcor circle2-ycor
              ]
            ]
          ]

          if number = 3 [
            let circle1-xcor 0
            let circle1-ycor 0
            let circle2-xcor 0
            let circle2-ycor 0
            let circle3-xcor 0
            let circle3-ycor 0


            ifelse xcor > 0 [
              ifelse ycor > 0 [
                set circle2-ycor circle-ycor
                set circle1-ycor circle-ycor + nest-size + 4
                set circle1-xcor circle-xcor
                set circle2-xcor circle-xcor + nest-size + 4
                set circle3-xcor circle-xcor + nest-size + 4
                set circle3-ycor circle-ycor + nest-size + 4
              ][ifelse ycor < 0
                [
                set circle1-xcor circle-xcor
                set circle2-xcor circle-xcor + nest-size + 4
                set circle2-ycor circle-ycor
                set circle1-ycor circle-ycor - nest-size - 4
                set circle3-xcor circle-xcor + nest-size + 4
                set circle3-ycor circle-ycor - nest-size - 4
                ][
                set circle1-xcor circle-xcor + nest-size + 3
                set circle2-xcor circle-xcor + nest-size + 3
                set circle2-ycor circle-ycor + nest-size + 3
                set circle1-ycor circle-ycor - nest-size - 3
                set circle3-xcor circle-xcor + nest-size + 7
                set circle3-ycor circle-ycor
                ]]]
            [ifelse xcor < 0 [
              ifelse ycor > 0 [
                set circle2-ycor circle-ycor
                set circle1-ycor circle-ycor + nest-size + 4
                set circle1-xcor circle-xcor
                set circle2-xcor circle-xcor - nest-size - 4
                set circle3-xcor circle-xcor - nest-size - 4
                set circle3-ycor circle-ycor + nest-size + 4
              ][ifelse ycor < 0
                [
                set circle1-xcor circle-xcor
                set circle2-xcor circle-xcor - nest-size - 4
                set circle2-ycor circle-ycor
                set circle1-ycor circle-ycor - nest-size - 4
                set circle3-xcor circle-xcor - nest-size - 4
                set circle3-ycor circle-ycor - nest-size - 4
                ][
                set circle1-xcor circle-xcor - nest-size - 3
                set circle2-xcor circle-xcor - nest-size - 3
                set circle2-ycor circle-ycor + nest-size + 3
                set circle1-ycor circle-ycor - nest-size - 3
                set circle3-xcor circle-xcor - nest-size - 7
                set circle3-ycor circle-ycor
                ]]
            ][
              ifelse ycor > 0 [
                set circle2-ycor circle-ycor + nest-size + 3
                set circle1-ycor circle-ycor + nest-size + 3
                set circle1-xcor circle-xcor + nest-size + 3
                set circle2-xcor circle-xcor - nest-size - 3
                set circle3-xcor circle-xcor
                set circle3-ycor circle-ycor + nest-size + 7
              ]
                [
                set circle1-xcor circle-xcor + nest-size + 3
                set circle2-xcor circle-xcor - nest-size - 3
                set circle2-ycor circle-ycor - nest-size - 3
                set circle1-ycor circle-ycor - nest-size - 3
                set circle3-xcor circle-xcor
                set circle3-ycor circle-ycor - nest-size - 7
                ]]
            ]
            hatch 1 [
                set shape "triangle"
                set size 2
                set color red
                setxy circle1-xcor circle1-ycor
              ]
            hatch 1 [
                set shape "star"
                set size 2
                set color yellow
                setxy circle2-xcor circle2-ycor
              ]
            hatch 1 [
                set shape "square"
                set size 2
                set color violet
                setxy circle3-xcor circle3-ycor
            ]
          ]
        ]

      set j j + 1

    ]
end

to setup-ants
  create-ants colony-size
  [
    set xcor 0
    set ycor 0
    set size 1
    set color brown
    set shape "bug"
    set class "nestant"
    set current-vote nobody
    set going-to nobody
    set quorum-threshold (quorum-percent * colony-size / 100)
    set transports 0
    set waiting int(random-exponential wait-time)
    set carrying 0
    set accept-threshold 50
    set commitment commitment-base
    set trail-influence trail-influence-base
    set scout-ant 0
  ]
end

to setup-patches
  ask patches
   [
     set pheromone 0
     recolor-patch
   ]
end

to recolor-patch  ; recolour patches according to pheromone
  set pcolor scale-color green pheromone 0.1 10
  if patch-ID > 0 [set pcolor grey]
end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Go procedures
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to avoid-double-marking ; move agents which have already visited a nest outside the nest area when they move on to avoid repeat actions
      ifelse going-to = nobody;
        [rt 180] ; scouts which are still undecided just about face
        [face going-to] ; others head for their goal
       fd nest-size
end

to stay-in-nest ; ants stay in home nest until they become scouts
  if random-float 100 < scout-chance [set class "scout"] ; scouts become active following a Poisson process
end

to search
  ;  ants move randomly or follow encountered trails if trail influence is enough
  ;  ants compare current site to accept threshold and keep searching until an acceptable nest is found
  ;  ants accepting a site change class to decided
  if random 100 < trail-influence [orient-to-trail]
  move
  let ID [patch-ID] of patch-here

  if ID > 0 and ID < 99  ; if arrive at a potential new nest site
    [
      ;print(ID)
      set scout-ant 1
      ;print ([quality] of nest ID)
      if [quality-class] of nest ID = "good"[
        ifelse [quality] of nest ID >= accept-threshold
        [set accept-threshold [quality] of nest ID
          ask nest ID
          [set quality-class "good"
            set color yellow
          ]
          set class "decided"
          set color red
          set current-vote nest ID
          ask nest ID [set votes votes + 1]
          set going-to nest 0]
        [ask nest ID [
          set quality-class "bad"
          set color orange
        ]]
      ]

      if [first-in] of nest ID = 0
        [
          ask nest ID [set first-in ticks]
        ]
      ifelse quality-stay?
        [set waiting ceiling (random-exponential wait-time * ([quality] of nest ID / 100))]
        [set waiting int(random-exponential wait-time)]

     ]
end

to recruit
  ; ants lay trail to preferred nest and check for quorum when in new sites
  ; ants can return to scout class if they lose committment to their current preferred site
  ifelse random 100 < (commitment)  ;; ants lose interest sometimes and go back to scouting
     [
       lay-trail
       ifelse random 100 < 50
         [face going-to]
         [orient-to-trail]
       move
       let ID [patch-ID] of patch-here
       if ID = [who] of current-vote ;; arrived at current vote
         [ifelse [quality-class] of nest ID = "good"[
           set going-to nest 0
           ifelse quality-stay?
             [set waiting ceiling (random-exponential wait-time * ([quality] of nest ID / 100))]
             [set waiting int(random-exponential wait-time)]
         ][
           set class "scout"
           set color brown
           set going-to nobody
           set current-vote nobody
         ]
         ]
       if ID = 99    ;; arrive at home
         [
           set going-to current-vote
           set waiting int(random-exponential wait-time)
         ]
     ] ; finish if still interested
     [
      set class "scout"
      set color brown
      set going-to nobody
      set current-vote nobody
     ] ; finish if lost interest

end

to transport
  ; ants move brood to preferred site
  ; ants continue to lay trails
  lay-trail
  ifelse random 100 < 50   ;; ants balance trail use and private information
   [face going-to]
   [orient-to-trail]
  move
  let ID [patch-ID] of patch-here
  if ID = [who] of current-vote    ;; arrived at current vote
    [
      set going-to nest 0
      if carrying = 1 [deposit-brood nest ID]
    ]
  if ID = 99    ;; arrive at home
    [
      set going-to current-vote
      if carrying = 0 [collect-brood nest 0]
    ]

end

to move
  ;speeds (mean and SD):
  ;
  ;disc : 3.92+1.28
  ;ass  : 4.24+1.38
  ;trans: 4.79+9.95
   waggle
   if class = "scout" [fd move-speed]
   if class = "decided" [fd move-speed * 1.08]
   if class = "transporter" [fd move-speed * 1.22]
end

to lay-trail
  set pheromone pheromone + pheromone-deposition
end

to collect-brood [location] ; ants arriving at home remove a brood item
  if [brood] of location > 0
    [
      ask location [
        set brood brood - 1
        if brood < 0 [set brood 0]
      ]
      set carrying 1 ;; add brood to transporter
    ]
end

to deposit-brood [nest-visited] ; ants arriving at their preferred site deposit a brood item
  if [brood] of nest-visited = 0 [ask nest-visited [set first-trans ticks]]
  ask nest-visited [set brood brood + 1]
  set carrying 0
  set transports transports + 1
end


to check-quorum  [ID]
  ; ants present at a new site assess the number of other ants present and compare this to their internal quorum threshold
  ; assessment may be subject to scalar error following Weber's law if selected
  ; those achieving a quorum switch class to transporter ant
   let current-count 0
   let base-count 0
   set base-count count ants-on patches with [patch-ID = ID]
   ifelse QT-error?  ; if count of ants for quorum suffers from scalar error, calculate based on Cronin 2014 Animal Cogition 17:1261–1268 parameters (error increases with count size)
     [
       let WeberFrac base-count * -0.005 + (count-WF / 100) ; weber fraction is proportional to number present (declining function with intercept based on slider)
       let countAAD WeberFrac * base-count ; AAD is Weber fraction of original count
       let countSD 1.4826 * countAAD ; convert the AAD to SD
       set current-count random-normal base-count  countSD ; set 'this guess' quorum
     ]
     [set current-count base-count]  ; if not including error just use base quorum
   if (current-count >= quorum-threshold)  ; if apparent ants here exceed quorum threshold, switch status
    [
      set class "transporter"
      set color blue
      set going-to nest 0
      set current-vote nest ID
      if [switchers] of nest ID = 0 [ask nest ID [set tq ticks]] ;set quorum achieved time (tq) for first switching ant
      ask nest ID [set switchers switchers + 1] ; increment number of votes for this site
    ]
end


to waggle ; random move direction adjustment
  ifelse random 100 < 50
    [rt random 45]
    [lt random 45]
  if not can-move? 1 [ rt 180 ]
end

to set-results
  ; sets values for model output parameters
  let disc-list nests with [first-in != 0]  ; create agentset of nests that have been entered at least once
  set first-discovery-time [first-in] of min-one-of disc-list [first-in]
  set first-nest-discovered [who] of min-one-of disc-list [first-in]
  set nest-chosen [who] of max-one-of nests [brood]
  set chosen-nest-discovery [first-in] of nest nest-chosen
  set chosen-nest-assessment [tq] of nest nest-chosen - [first-in] of nest nest-chosen
  set chosen-nest-transport ticks - [first-trans] of nest nest-chosen
  ifelse [quality-class] of nest nest-chosen = "good"
    [set success 1]
    [set success 0]
  let brood-nests nests with [brood > 0]
  ifelse count brood-nests > 1
    [set split 1]
    [set split 0]
  set best-nest [who] of max-one-of nests [quality]
  set nests-found count nests with [first-in != 0]
  set nests-with-votes count nests with [votes > 0]
  set chosen-votes [votes] of nest nest-chosen
  set other-votes sum [votes] of nests - chosen-votes
  set scouts count ants with [scout-ant = 1]
end

;; orientation functions ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to orient-to-trail
  ; ants turn to face direction of higher pheromone concentration if present in sufficient amounts
  ; turning direction is dependent on relative pheromone strength following Weber's law
  let scent-ahead scent-at-angle   0
  let scent-right scent-at-angle  45
  let scent-left  scent-at-angle -45
  if scent-ahead + scent-right + scent-left > 0.1    ; if only faint trail, ignore it
      [
      if (scent-right > scent-ahead) or (scent-left > scent-ahead)  ;; turn if left or right scent is higher than in front
        [
          ifelse scent-right > scent-left
          [
            let weber-fraction 1 - (scent-ahead / scent-right)  ;; calculate propoprotionate differnece in signal strength ahead and at angle
            rt (weber-fraction * 45)                        ;; turn up to 45 degrees scaled by relative strength of pheremone
          ]
          [
            let weber-fraction 1 - (scent-ahead / scent-left)
            lt (weber-fraction * 45)
          ]
        ]
        ]
   if not can-move? 1 [rt 180]
end

to-report scent-at-angle [angle]
  let p patch-right-and-ahead angle 1
  ifelse p = nobody
    [ report 0 ]
    [report [pheromone] of p]
end


to recolor-nests ; sets nest colour based on current quality
  ask nests
    [ifelse quality-class = "good"
      [set color green]
      [set color grey]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
837
23
1374
561
-1
-1
5.24
1
10
1
1
1
0
0
0
1
-50
50
-50
50
0
0
1
ticks
30.0

SLIDER
18
154
175
187
colony-size
colony-size
1
100
40.0
1
1
NIL
HORIZONTAL

SLIDER
179
88
328
121
pheromone-deposition
pheromone-deposition
0
10
1.0
0.1
1
NIL
HORIZONTAL

SLIDER
20
37
171
70
quorum-percent
quorum-percent
1
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
700
655
857
688
brood-percent
brood-percent
0
300
65.0
1
1
NIL
HORIZONTAL

TEXTBOX
22
12
172
30
Ant
12
0.0
1

TEXTBOX
22
130
172
148
Physical
12
0.0
1

BUTTON
371
43
432
76
Setup
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

SLIDER
1211
736
1361
769
diffusion-rate
diffusion-rate
0
1
0.56
0.01
1
NIL
HORIZONTAL

SLIDER
1212
771
1361
804
evaporation-rate
evaporation-rate
0
10
0.05
0.01
1
NIL
HORIZONTAL

BUTTON
372
83
435
116
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
1028
655
1178
688
wait-time
wait-time
0
500
60.0
10
1
NIL
HORIZONTAL

CHOOSER
179
34
327
79
number-of-nests
number-of-nests
1 2 4 8 16
3

SWITCH
1027
764
1178
797
quality-stay?
quality-stay?
0
1
-1000

PLOT
478
403
825
553
nest populations
NIL
NIL
1.0
16.0
0.0
10.0
true
true
"clear-plot\nset-plot-x-range 0 16" "clear-plot"
PENS
"nest 1" 1.0 1 -11221820 true "" "plotxy 1 count ants-on patches with [patch-ID = 1]"
"nest 2" 1.0 1 -7500403 true "" "plotxy 2 count ants-on patches with [patch-ID = 2]"
"nest 3" 1.0 1 -6459832 true "" "plotxy 3 count ants-on patches with [patch-ID =  3]"
"nest 4" 1.0 1 -16050907 true "" "plotxy 4 count ants-on patches with [patch-ID =  4]"
"nest 5" 1.0 1 -2674135 true "" "plotxy 5 count ants-on patches with [patch-ID =  5]"
"nest 6" 1.0 1 -1184463 true "" "plotxy 6 count ants-on patches with [patch-ID =  6]"
"pen-7" 1.0 1 -13840069 true "" "plotxy 7 count ants-on patches with [patch-ID =  7]"
"pen-8" 1.0 1 -14835848 true "" "plotxy 8 count ants-on patches with [patch-ID =  8]"
"pen-9" 1.0 1 -13791810 true "" "plotxy 9 count ants-on patches with [patch-ID =  9]"
"pen-10" 1.0 1 -13345367 true "" "plotxy 10 count ants-on patches with [patch-ID =  10]"
"pen-11" 1.0 1 -8630108 true "" "plotxy 11 count ants-on patches with [patch-ID =  11]"
"pen-12" 1.0 1 -5825686 true "" "plotxy 12 count ants-on patches with [patch-ID =  12]"
"pen-13" 1.0 1 -2064490 true "" "plotxy 13 count ants-on patches with [patch-ID =  13]"
"pen-14" 1.0 1 -2382653 true "" "plotxy 14 count ants-on patches with [patch-ID =  14]"
"pen-15" 1.0 1 -2674135 true "" "plotxy 15 count ants-on patches with [patch-ID =  15]"
"pen-16" 1.0 1 -16777216 true "" "plotxy 16 count ants-on patches with [patch-ID =  16]"

PLOT
443
123
603
246
Active ants
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot colony-size - (count ants with [class = \"nestant\"])"

PLOT
453
260
657
398
Task distribution
NIL
NIL
0.0
4.0
0.0
10.0
true
true
"" ""
PENS
"nest ants" 1.0 1 -16777216 true "" "plot-pen-reset plotxy 0 count ants with [class = \"nestant\"]"
"scouts" 1.0 1 -7500403 true "" "plot-pen-reset plotxy 1 count ants with [class = \"scout\"]"
"decided" 1.0 1 -2674135 true "" "plot-pen-reset plotxy 2 count ants with [class = \"decided\"]"
"transporters" 1.0 1 -955883 true "" "plot-pen-reset plotxy 3 count ants with [class = \"transporter\"]"

TEXTBOX
187
15
337
33
Environmental
11
0.0
1

SLIDER
863
656
1015
689
acceptSD
acceptSD
0
50
20.0
1
1
NIL
HORIZONTAL

SLIDER
1030
838
1182
871
count-WF
count-WF
1
25
23.0
1
1
NIL
HORIZONTAL

SLIDER
19
86
171
119
commitment-base
commitment-base
50
99.9
99.0
0.1
1
%
HORIZONTAL

SLIDER
1026
691
1178
724
scout-chance
scout-chance
0
1
1.0
0.01
1
NIL
HORIZONTAL

MONITOR
756
65
813
110
QT
(colony-size * quorum-percent / 100 ) + 0.51
1
1
11

SLIDER
1027
727
1179
760
move-speed
move-speed
0
10
1.0
0.1
1
NIL
HORIZONTAL

PLOT
662
259
836
400
Temporal nest populations
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"nest 1" 1.0 0 -8275240 true "" "plot count ants-on patches with [patch-ID = 1]"
"nest 2" 1.0 0 -7500403 true "" "plot count ants-on patches with [patch-ID = 2]"
"nest 3" 1.0 0 -6459832 true "" "plot count ants-on patches with [patch-ID = 3]"
"nest 4" 1.0 0 -955883 true "" "plot count ants-on patches with [patch-ID = 4]"

SLIDER
861
745
1013
778
trail-influence-base
trail-influence-base
0
100
95.0
1
1
NIL
HORIZONTAL

MONITOR
696
66
756
111
Best-nest
best-nest
17
1
11

MONITOR
683
10
740
55
success
success
17
1
11

MONITOR
639
67
696
112
Result
result
17
1
11

SLIDER
1211
693
1359
726
max-ticks
max-ticks
0
20000
20000.0
100
1
NIL
HORIZONTAL

SLIDER
1210
653
1358
686
nest-size
nest-size
0
5
5.0
1
1
NIL
HORIZONTAL

MONITOR
625
117
682
162
DISC
chosen-nest-discovery
17
1
11

MONITOR
686
117
739
162
ASSESS
chosen-nest-assessment
17
1
11

MONITOR
742
117
797
162
TRANS
chosen-nest-transport
17
1
11

MONITOR
503
67
572
112
First-found
first-nest-discovered
17
1
11

MONITOR
574
67
636
112
find-time
first-discovery-time
17
1
11

MONITOR
623
10
680
55
chosen
nest-chosen
17
1
11

SWITCH
1029
804
1182
837
QT-error?
QT-error?
0
1
-1000

MONITOR
504
10
561
55
Split
split
17
1
11

MONITOR
563
10
620
55
Found
nests-found
17
1
11

CHOOSER
864
690
1017
735
accept-distribution
accept-distribution
"normal" "Poisson"
1

TEXTBOX
18
190
168
208
Nest
12
0.0
1

SWITCH
14
212
130
245
Nest1Food
Nest1Food
0
1
-1000

SWITCH
145
212
289
245
Nest1Protection
Nest1Protection
0
1
-1000

SWITCH
301
211
437
244
Nest1Predator
Nest1Predator
1
1
-1000

SWITCH
14
257
130
290
Nest2Food
Nest2Food
1
1
-1000

SWITCH
145
257
289
290
Nest2Protection
Nest2Protection
0
1
-1000

SWITCH
301
257
437
290
Nest2Predator
Nest2Predator
1
1
-1000

SWITCH
14
302
130
335
Nest3Food
Nest3Food
0
1
-1000

SWITCH
14
347
130
380
Nest4Food
Nest4Food
0
1
-1000

SWITCH
14
391
130
424
Nest5Food
Nest5Food
0
1
-1000

SWITCH
14
436
130
469
Nest6Food
Nest6Food
0
1
-1000

SWITCH
14
482
130
515
Nest7Food
Nest7Food
0
1
-1000

SWITCH
15
526
131
559
Nest8Food
Nest8Food
0
1
-1000

SWITCH
15
570
131
603
Nest9Food
Nest9Food
1
1
-1000

SWITCH
15
614
138
647
Nest10Food
Nest10Food
0
1
-1000

SWITCH
15
660
138
693
Nest11Food
Nest11Food
1
1
-1000

SWITCH
14
706
137
739
Nest12Food
Nest12Food
1
1
-1000

SWITCH
14
751
137
784
Nest13Food
Nest13Food
1
1
-1000

SWITCH
14
796
137
829
Nest14Food
Nest14Food
0
1
-1000

SWITCH
14
842
137
875
Nest15Food
Nest15Food
1
1
-1000

SWITCH
14
888
137
921
Nest16Food
Nest16Food
0
1
-1000

SWITCH
145
304
289
337
Nest3Protection
Nest3Protection
1
1
-1000

SWITCH
145
349
289
382
Nest4Protection
Nest4Protection
1
1
-1000

SWITCH
145
395
289
428
Nest5Protection
Nest5Protection
1
1
-1000

SWITCH
146
438
290
471
Nest6Protection
Nest6Protection
1
1
-1000

SWITCH
145
484
289
517
Nest7Protection
Nest7Protection
1
1
-1000

SWITCH
146
530
290
563
Nest8Protection
Nest8Protection
1
1
-1000

SWITCH
145
574
289
607
Nest9Protection
Nest9Protection
0
1
-1000

SWITCH
145
618
296
651
Nest10Protection
Nest10Protection
1
1
-1000

SWITCH
144
662
295
695
Nest11Protection
Nest11Protection
0
1
-1000

SWITCH
143
707
294
740
Nest12Protection
Nest12Protection
1
1
-1000

SWITCH
143
751
294
784
Nest13Protection
Nest13Protection
1
1
-1000

SWITCH
142
796
293
829
Nest14Protection
Nest14Protection
0
1
-1000

SWITCH
142
843
293
876
Nest15Protection
Nest15Protection
1
1
-1000

SWITCH
142
887
293
920
Nest16Protection
Nest16Protection
1
1
-1000

SWITCH
302
305
438
338
Nest3Predator
Nest3Predator
0
1
-1000

SWITCH
302
349
438
382
Nest4Predator
Nest4Predator
1
1
-1000

SWITCH
301
394
437
427
Nest5Predator
Nest5Predator
1
1
-1000

SWITCH
301
437
437
470
Nest6Predator
Nest6Predator
0
1
-1000

SWITCH
300
482
436
515
Nest7Predator
Nest7Predator
1
1
-1000

SWITCH
300
528
436
561
Nest8Predator
Nest8Predator
1
1
-1000

SWITCH
300
573
436
606
Nest9Predator
Nest9Predator
0
1
-1000

SWITCH
300
617
443
650
Nest10Predator
Nest10Predator
1
1
-1000

SWITCH
301
662
444
695
Nest11Predator
Nest11Predator
1
1
-1000

SWITCH
300
706
443
739
Nest12Predator
Nest12Predator
1
1
-1000

SWITCH
300
749
443
782
Nest13Predator
Nest13Predator
1
1
-1000

SWITCH
300
795
443
828
Nest14Predator
Nest14Predator
1
1
-1000

SWITCH
300
843
443
876
Nest15Predator
Nest15Predator
1
1
-1000

SWITCH
301
886
444
919
Nest16Predator
Nest16Predator
1
1
-1000

@#$#@#$#@
## WHAT IS IT?

This model simulates the collective decision-making process during nest-site selection in the ant Myrmecina nipponica, a species which combines pheromone trails and quorum responses to make collective decisions. This process is characterised by interactions among individuals (ants) using local rules to produce a system-level (colony) decision. It incorporates various components of the emigration process, including environmental survey, information exchange, positive feedback, and maintenance of group cohesion. Several components of the choice mechanism have been quantified from empirical studies (see references given below) while others remain cryptic and were thus initially assigned arbitrary values. The purpose of this model is to assess how cryptic and observable properties of individual behaviour compile to produce system-level responses in different simulated contexts. The model is designed to take an ‘ants-eye-view’ of the decision-making process, and thus all system (colony) level outcomes emerge from local rules used by individual ants without global direction. 

## HOW IT WORKS

Agents behaviour is governed by individual rules which depend on rate and threshold parameters for environmental and social stimuli. Agents are identical in basic structure and function but can vary in a) thresholds of various parameters, and b) their behavioural ‘class’ which determines how they interact with their environment. 
A variable number of agents (1-100) comprises one colony as set by the user.

## HOW TO USE IT

Users set the following varaibles then allow the nest-selection process to proceed. Variables are divided into Ant, Physical and Environmental characters:

Ant characters

wait-time -		Time spent stationary when arriving at sites
scout-chance -		Probability of switching from inactive nest ant to scout per step
move-speed -		Move distance each step
quality-stay? -		Wait time influenced by nest quality 
quorum-percent -	Quorum threshold as a percentage of colony size
QT-error	 -	Quorum threshold estimates subject to scalar error
count-WF	 -	Weber fraction for scalar error
base-accept-threshold -	Accept threshold for individual ants (base value)
acceptSD	 -	Standard deviation applied to base accept threshold for each individual ant
accept-distribution - Distribution from which accept values are drawn
commitment-base		 - Percentage chance ants remain committed to currently favoured site each step
trail-influence-base	 - Percentage chance trail will influence ant navigation per step

Environmental characters

max-ticks	 -	Time limit on emigration in steps
pheromone-deposition -	Amount of pheromone deposited per step
diffusion-rate		 - Diffusion rate of pheromone per step
evaporation-rate	 - Evaporation rate of pheromone per step
number-of-nests		 - Number of new nests available
good-nests		 - Number of available new nests which are of ‘good’ quality
nest-size		 - Area covered by each nest in patches
quality-good-nests	 - Quality score of ‘good’ nests
quality-bad-nests	 - Quality score of ‘bad’ nests


Physical characters

colony-size		 - Number of ants in the colony
brood-percent		 - Percentage of colony size equivalent in brood items
dynamic-environment?	 - Nest quality switches during emigrations
switch-point		 - Point at which nest quality switches

## THINGS TO NOTICE

The following reporters and outputs are delivered during and/or at the end of each simulation.

Plots:

Active ants - number of ants currently not resting in the nest

Task distribution - number of ants of each different behavioural class

Temporal nest population - number of ants in each new candidate nest over time. This is useful for observing dynamic changes in recruitment to each nest

Nest populations - current number of ants in each candidate nest. Useful for observing when quorum thresholds are attained

Reporters (also output to file if using Behaviour Space):

Split - colony relocates to more than one destination nest

Found - Number of nests ants entered during the time limit

Chosen - Nest eventually emigrated to (containing the majority of brood if split)

Success - Colony emigrated to best available nest (1/0)

First found - First nest any ant entered
 
Find time - time of first entry in steps

Result - Emigration completed before time limit

Best nest - ID of nest with highest quality

QT - Quorum threshold

DISC - duration of the discovery phase in steps

ASSESS - duration of the assessment phase in steps

TRANS - duration of the transport phase in steps


## THINGS TO TRY

See publication below

## EXTENDING THE MODEL

Different forms of recruitment (outside of trail following) could be implemented, so see how these influence the collective outcome. 

## NETLOGO FEATURES

None

## RELATED MODELS

See publication below

## CREDITS AND REFERENCES

This model is used in the following publication:

Cronin, A. L. in review. Individual rules underlying collective-decision making in a mass-recruiting ant: insights from an agent-based model. 
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
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

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

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="cs accept sd 8.3" repetitions="10" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count ants</metric>
    <metric>count ants with [transports &gt; 0]</metric>
    <metric>best-nest</metric>
    <metric>result</metric>
    <metric>success</metric>
    <metric>first-nest-discovered</metric>
    <metric>first-discovery-time</metric>
    <metric>nest-chosen</metric>
    <metric>chosen-nest-discovery</metric>
    <metric>chosen-nest-assessment</metric>
    <metric>chosen-nest-transport</metric>
    <metric>split</metric>
    <metric>nests-found</metric>
    <enumeratedValueSet variable="acceptSD">
      <value value="5"/>
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="active-ants">
      <value value="55"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="base-accept-threshold">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="brood-percent">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colony-size">
      <value value="14"/>
      <value value="28"/>
      <value value="53"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment">
      <value value="99.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="count-WF">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffusion-rate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="evaporation-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="feedback-strength">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="good-nests">
      <value value="&quot;single&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="15000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-nests">
      <value value="2"/>
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nest-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pheromone-deposition">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-dep-commit?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-good-nests">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-bad-nests">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-stay?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-percent">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="QT-error?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scout-chance">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence">
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transporter-feedback?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-time">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="negative-feedback">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="commit  sd 8.4" repetitions="10" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count ants</metric>
    <metric>count ants with [transports &gt; 0]</metric>
    <metric>best-nest</metric>
    <metric>result</metric>
    <metric>success</metric>
    <metric>first-nest-discovered</metric>
    <metric>first-discovery-time</metric>
    <metric>nest-chosen</metric>
    <metric>chosen-nest-discovery</metric>
    <metric>chosen-nest-assessment</metric>
    <metric>chosen-nest-transport</metric>
    <metric>split</metric>
    <metric>nests-found</metric>
    <enumeratedValueSet variable="acceptSD">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="active-ants">
      <value value="55"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="base-accept-threshold">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="brood-percent">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colony-size">
      <value value="14"/>
      <value value="53"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment-base">
      <value value="80"/>
      <value value="85"/>
      <value value="90"/>
      <value value="95"/>
      <value value="99"/>
      <value value="99.5"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment-SD">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="count-WF">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffusion-rate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="evaporation-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="feedback-strength">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="good-nests">
      <value value="&quot;single&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="15000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-nests">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nest-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pheromone-deposition">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-dep-commit?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-good-nests">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-bad-nests">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-stay?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-percent">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-SD">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="QT-error?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scout-chance">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence-base">
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence-SD">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transporter-feedback?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-time">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="negative-feedback">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="social private info base 8.4" repetitions="10" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count ants</metric>
    <metric>count ants with [transports &gt; 0]</metric>
    <metric>best-nest</metric>
    <metric>result</metric>
    <metric>success</metric>
    <metric>first-nest-discovered</metric>
    <metric>first-discovery-time</metric>
    <metric>nest-chosen</metric>
    <metric>chosen-nest-discovery</metric>
    <metric>chosen-nest-assessment</metric>
    <metric>chosen-nest-transport</metric>
    <metric>split</metric>
    <metric>nests-found</metric>
    <enumeratedValueSet variable="acceptSD">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="active-ants">
      <value value="55"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="base-accept-threshold">
      <value value="1"/>
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
      <value value="60"/>
      <value value="70"/>
      <value value="80"/>
      <value value="90"/>
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="brood-percent">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colony-size">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment-base">
      <value value="99.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment-SD">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="count-WF">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffusion-rate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="evaporation-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="feedback-strength">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="good-nests">
      <value value="&quot;single&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="15000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-nests">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nest-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pheromone-deposition">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-dep-commit?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-good-nests">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-bad-nests">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-stay?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-percent">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-SD">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="QT-error?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scout-chance">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence-base">
      <value value="1"/>
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
      <value value="60"/>
      <value value="70"/>
      <value value="80"/>
      <value value="90"/>
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence-SD">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transporter-feedback?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-time">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="negative-feedback">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="discrimination 8.4" repetitions="10" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count ants</metric>
    <metric>count ants with [transports &gt; 0]</metric>
    <metric>best-nest</metric>
    <metric>result</metric>
    <metric>success</metric>
    <metric>first-nest-discovered</metric>
    <metric>first-discovery-time</metric>
    <metric>nest-chosen</metric>
    <metric>chosen-nest-discovery</metric>
    <metric>chosen-nest-assessment</metric>
    <metric>chosen-nest-transport</metric>
    <metric>split</metric>
    <metric>nests-found</metric>
    <enumeratedValueSet variable="acceptSD">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="active-ants">
      <value value="55"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="base-accept-threshold">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="brood-percent">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colony-size">
      <value value="15"/>
      <value value="30"/>
      <value value="45"/>
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment-base">
      <value value="99.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment-SD">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="count-WF">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffusion-rate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="evaporation-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="feedback-strength">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="good-nests">
      <value value="&quot;single&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="15000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-nests">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nest-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pheromone-deposition">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-dep-commit?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-good-nests">
      <value value="60"/>
      <value value="70"/>
      <value value="80"/>
      <value value="90"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-bad-nests">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-stay?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-percent">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-SD">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="QT-error?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scout-chance">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence-base">
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence-SD">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transporter-feedback?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-time">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="negative-feedback">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="base parameters 8.4" repetitions="10" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count ants</metric>
    <metric>count ants with [transports &gt; 0]</metric>
    <metric>best-nest</metric>
    <metric>result</metric>
    <metric>success</metric>
    <metric>first-nest-discovered</metric>
    <metric>first-discovery-time</metric>
    <metric>nest-chosen</metric>
    <metric>chosen-nest-discovery</metric>
    <metric>chosen-nest-assessment</metric>
    <metric>chosen-nest-transport</metric>
    <metric>split</metric>
    <metric>nests-found</metric>
    <enumeratedValueSet variable="acceptSD">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="active-ants">
      <value value="55"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="base-accept-threshold">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="brood-percent">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colony-size">
      <value value="15"/>
      <value value="30"/>
      <value value="45"/>
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment-base">
      <value value="99.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment-SD">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="count-WF">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffusion-rate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="evaporation-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="feedback-strength">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="good-nests">
      <value value="&quot;single&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="15000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-nests">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nest-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pheromone-deposition">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-dep-commit?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-good-nests">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-bad-nests">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-stay?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-percent">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-SD">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="QT-error?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scout-chance">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence-base">
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence-SD">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transporter-feedback?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-time">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="negative-feedback">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="base parameters trail 8.4" repetitions="10" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count ants</metric>
    <metric>count ants with [transports &gt; 0]</metric>
    <metric>best-nest</metric>
    <metric>result</metric>
    <metric>success</metric>
    <metric>first-nest-discovered</metric>
    <metric>first-discovery-time</metric>
    <metric>nest-chosen</metric>
    <metric>chosen-nest-discovery</metric>
    <metric>chosen-nest-assessment</metric>
    <metric>chosen-nest-transport</metric>
    <metric>split</metric>
    <metric>nests-found</metric>
    <enumeratedValueSet variable="acceptSD">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="active-ants">
      <value value="55"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="base-accept-threshold">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="brood-percent">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colony-size">
      <value value="15"/>
      <value value="30"/>
      <value value="45"/>
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment-base">
      <value value="99.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment-SD">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="count-WF">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffusion-rate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="evaporation-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="feedback-strength">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="good-nests">
      <value value="&quot;single&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="15000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-nests">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nest-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pheromone-deposition">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-dep-commit?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-good-nests">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-bad-nests">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-stay?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-percent">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-SD">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="QT-error?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scout-chance">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence-base">
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence-SD">
      <value value="0"/>
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transporter-feedback?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-time">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="negative-feedback">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="base parameters quorum SD 8.4" repetitions="10" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count ants</metric>
    <metric>count ants with [transports &gt; 0]</metric>
    <metric>best-nest</metric>
    <metric>result</metric>
    <metric>success</metric>
    <metric>first-nest-discovered</metric>
    <metric>first-discovery-time</metric>
    <metric>nest-chosen</metric>
    <metric>chosen-nest-discovery</metric>
    <metric>chosen-nest-assessment</metric>
    <metric>chosen-nest-transport</metric>
    <metric>split</metric>
    <metric>nests-found</metric>
    <enumeratedValueSet variable="acceptSD">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="active-ants">
      <value value="55"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="base-accept-threshold">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="brood-percent">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colony-size">
      <value value="15"/>
      <value value="30"/>
      <value value="45"/>
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment-base">
      <value value="99.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment-SD">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="count-WF">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffusion-rate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="evaporation-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="feedback-strength">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="good-nests">
      <value value="&quot;single&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="15000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-nests">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nest-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pheromone-deposition">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-dep-commit?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-good-nests">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-bad-nests">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-stay?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-percent">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-SD">
      <value value="0"/>
      <value value="5"/>
      <value value="10"/>
      <value value="15"/>
      <value value="20"/>
      <value value="25"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="QT-error?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scout-chance">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence-base">
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence-SD">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transporter-feedback?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-time">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="negative-feedback">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="col size 50% nests 8.4" repetitions="10" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count ants</metric>
    <metric>count ants with [transports &gt; 0]</metric>
    <metric>best-nest</metric>
    <metric>result</metric>
    <metric>success</metric>
    <metric>first-nest-discovered</metric>
    <metric>first-discovery-time</metric>
    <metric>nest-chosen</metric>
    <metric>chosen-nest-discovery</metric>
    <metric>chosen-nest-assessment</metric>
    <metric>chosen-nest-transport</metric>
    <metric>split</metric>
    <metric>nests-found</metric>
    <enumeratedValueSet variable="acceptSD">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="active-ants">
      <value value="55"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="base-accept-threshold">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="brood-percent">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colony-size">
      <value value="15"/>
      <value value="30"/>
      <value value="45"/>
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment-base">
      <value value="99.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment-SD">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="count-WF">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffusion-rate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="evaporation-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="feedback-strength">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="good-nests">
      <value value="&quot;single&quot;"/>
      <value value="&quot;half&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="15000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-nests">
      <value value="2"/>
      <value value="4"/>
      <value value="8"/>
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nest-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pheromone-deposition">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-dep-commit?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-good-nests">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-bad-nests">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-stay?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-percent">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-SD">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="QT-error?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scout-chance">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence-base">
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence-SD">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transporter-feedback?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-time">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="negative-feedback">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="col size 50% nests all col sz 50 reps 8.4" repetitions="50" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count ants</metric>
    <metric>count ants with [transports &gt; 0]</metric>
    <metric>best-nest</metric>
    <metric>result</metric>
    <metric>success</metric>
    <metric>first-nest-discovered</metric>
    <metric>first-discovery-time</metric>
    <metric>nest-chosen</metric>
    <metric>chosen-nest-discovery</metric>
    <metric>chosen-nest-assessment</metric>
    <metric>chosen-nest-transport</metric>
    <metric>split</metric>
    <metric>nests-found</metric>
    <enumeratedValueSet variable="acceptSD">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="active-ants">
      <value value="55"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="base-accept-threshold">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="brood-percent">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colony-size">
      <value value="10"/>
      <value value="15"/>
      <value value="20"/>
      <value value="25"/>
      <value value="30"/>
      <value value="35"/>
      <value value="40"/>
      <value value="45"/>
      <value value="50"/>
      <value value="55"/>
      <value value="60"/>
      <value value="65"/>
      <value value="70"/>
      <value value="75"/>
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment-base">
      <value value="99.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment-SD">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="count-WF">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffusion-rate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="evaporation-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="feedback-strength">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="good-nests">
      <value value="&quot;single&quot;"/>
      <value value="&quot;half&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="15000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-nests">
      <value value="2"/>
      <value value="4"/>
      <value value="8"/>
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nest-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pheromone-deposition">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-dep-commit?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-good-nests">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-bad-nests">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-stay?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-percent">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-SD">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="QT-error?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scout-chance">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence-base">
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence-SD">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transporter-feedback?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-time">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="negative-feedback">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="quorum 8.4" repetitions="50" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count ants</metric>
    <metric>count ants with [transports &gt; 0]</metric>
    <metric>best-nest</metric>
    <metric>result</metric>
    <metric>success</metric>
    <metric>first-nest-discovered</metric>
    <metric>first-discovery-time</metric>
    <metric>nest-chosen</metric>
    <metric>chosen-nest-discovery</metric>
    <metric>chosen-nest-assessment</metric>
    <metric>chosen-nest-transport</metric>
    <metric>split</metric>
    <metric>nests-found</metric>
    <enumeratedValueSet variable="acceptSD">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="active-ants">
      <value value="55"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="base-accept-threshold">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="brood-percent">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colony-size">
      <value value="10"/>
      <value value="15"/>
      <value value="20"/>
      <value value="25"/>
      <value value="30"/>
      <value value="35"/>
      <value value="40"/>
      <value value="45"/>
      <value value="50"/>
      <value value="55"/>
      <value value="60"/>
      <value value="65"/>
      <value value="70"/>
      <value value="75"/>
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment-base">
      <value value="99.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment-SD">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="count-WF">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffusion-rate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="evaporation-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="feedback-strength">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="good-nests">
      <value value="&quot;single&quot;"/>
      <value value="&quot;half&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="15000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-nests">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nest-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pheromone-deposition">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-dep-commit?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-good-nests">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-bad-nests">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-stay?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-percent">
      <value value="10"/>
      <value value="12.5"/>
      <value value="15"/>
      <value value="17.5"/>
      <value value="20"/>
      <value value="22.5"/>
      <value value="25"/>
      <value value="27.5"/>
      <value value="30"/>
      <value value="32.5"/>
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-SD">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="QT-error?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scout-chance">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence-base">
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence-SD">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transporter-feedback?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-time">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="negative-feedback">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="nest rel quality" repetitions="50" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count ants</metric>
    <metric>count ants with [transports &gt; 0]</metric>
    <metric>best-nest</metric>
    <metric>result</metric>
    <metric>success</metric>
    <metric>first-nest-discovered</metric>
    <metric>first-discovery-time</metric>
    <metric>nest-chosen</metric>
    <metric>chosen-nest-discovery</metric>
    <metric>chosen-nest-assessment</metric>
    <metric>chosen-nest-transport</metric>
    <metric>split</metric>
    <metric>nests-found</metric>
    <enumeratedValueSet variable="acceptSD">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="active-ants">
      <value value="55"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="base-accept-threshold">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="brood-percent">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colony-size">
      <value value="10"/>
      <value value="15"/>
      <value value="20"/>
      <value value="25"/>
      <value value="30"/>
      <value value="35"/>
      <value value="40"/>
      <value value="45"/>
      <value value="50"/>
      <value value="55"/>
      <value value="60"/>
      <value value="65"/>
      <value value="70"/>
      <value value="75"/>
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment-base">
      <value value="99.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment-SD">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="count-WF">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffusion-rate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="evaporation-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="feedback-strength">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="good-nests">
      <value value="&quot;single&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="15000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-nests">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nest-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pheromone-deposition">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-dep-commit?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-good-nests">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-bad-nests">
      <value value="50"/>
      <value value="55"/>
      <value value="60"/>
      <value value="65"/>
      <value value="70"/>
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-stay?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-percent">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-SD">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="QT-error?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scout-chance">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence-base">
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence-SD">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transporter-feedback?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-time">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="negative-feedback">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="quorum cs nests 8.5" repetitions="50" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count ants</metric>
    <metric>count ants with [transports &gt; 0]</metric>
    <metric>best-nest</metric>
    <metric>result</metric>
    <metric>success</metric>
    <metric>first-nest-discovered</metric>
    <metric>first-discovery-time</metric>
    <metric>nest-chosen</metric>
    <metric>chosen-nest-discovery</metric>
    <metric>chosen-nest-assessment</metric>
    <metric>chosen-nest-transport</metric>
    <metric>split</metric>
    <metric>nests-found</metric>
    <enumeratedValueSet variable="acceptSD">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="active-ants">
      <value value="55"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="base-accept-threshold">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="brood-percent">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colony-size">
      <value value="10"/>
      <value value="15"/>
      <value value="20"/>
      <value value="25"/>
      <value value="30"/>
      <value value="35"/>
      <value value="40"/>
      <value value="45"/>
      <value value="50"/>
      <value value="55"/>
      <value value="60"/>
      <value value="65"/>
      <value value="70"/>
      <value value="75"/>
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment-base">
      <value value="99.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment-SD">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="count-WF">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffusion-rate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="evaporation-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="feedback-strength">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="good-nests">
      <value value="&quot;single&quot;"/>
      <value value="&quot;half&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="15000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-nests">
      <value value="4"/>
      <value value="8"/>
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nest-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pheromone-deposition">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-dep-commit?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-good-nests">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-bad-nests">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-stay?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-percent">
      <value value="10"/>
      <value value="15"/>
      <value value="20"/>
      <value value="25"/>
      <value value="30"/>
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-SD">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="QT-error?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scout-chance">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence-base">
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence-SD">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transporter-feedback?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-time">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="negative-feedback">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="empirical rep 8.5" repetitions="50" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count ants</metric>
    <metric>count ants with [transports &gt; 0]</metric>
    <metric>best-nest</metric>
    <metric>result</metric>
    <metric>success</metric>
    <metric>first-nest-discovered</metric>
    <metric>first-discovery-time</metric>
    <metric>nest-chosen</metric>
    <metric>chosen-nest-discovery</metric>
    <metric>chosen-nest-assessment</metric>
    <metric>chosen-nest-transport</metric>
    <metric>split</metric>
    <metric>nests-found</metric>
    <enumeratedValueSet variable="acceptSD">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="active-ants">
      <value value="55"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="base-accept-threshold">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="brood-percent">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colony-size">
      <value value="13"/>
      <value value="27"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment-base">
      <value value="99.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment-SD">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="count-WF">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffusion-rate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="evaporation-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="feedback-strength">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="good-nests">
      <value value="&quot;single&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="15000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-nests">
      <value value="1"/>
      <value value="2"/>
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nest-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pheromone-deposition">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-dep-commit?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-good-nests">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-bad-nests">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-stay?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-percent">
      <value value="28"/>
      <value value="33"/>
      <value value="38"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-SD">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="QT-error?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scout-chance">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence-base">
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence-SD">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transporter-feedback?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-time">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="negative-feedback">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="empirical rep 8.5 neg fb" repetitions="50" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count ants</metric>
    <metric>count ants with [transports &gt; 0]</metric>
    <metric>best-nest</metric>
    <metric>result</metric>
    <metric>success</metric>
    <metric>first-nest-discovered</metric>
    <metric>first-discovery-time</metric>
    <metric>nest-chosen</metric>
    <metric>chosen-nest-discovery</metric>
    <metric>chosen-nest-assessment</metric>
    <metric>chosen-nest-transport</metric>
    <metric>split</metric>
    <metric>nests-found</metric>
    <enumeratedValueSet variable="acceptSD">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="active-ants">
      <value value="55"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="base-accept-threshold">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="brood-percent">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colony-size">
      <value value="13"/>
      <value value="27"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment-base">
      <value value="99.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment-SD">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="count-WF">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffusion-rate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="evaporation-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="feedback-strength">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="good-nests">
      <value value="&quot;single&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="15000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-nests">
      <value value="1"/>
      <value value="2"/>
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nest-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pheromone-deposition">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-dep-commit?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-good-nests">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-bad-nests">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-stay?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-percent">
      <value value="28"/>
      <value value="33"/>
      <value value="38"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-SD">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="QT-error?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scout-chance">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence-base">
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence-SD">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transporter-feedback?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-time">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="negative-feedback">
      <value value="1"/>
      <value value="2"/>
      <value value="5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="quality difference 8.5" repetitions="50" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count ants</metric>
    <metric>count ants with [transports &gt; 0]</metric>
    <metric>best-nest</metric>
    <metric>result</metric>
    <metric>success</metric>
    <metric>first-nest-discovered</metric>
    <metric>first-discovery-time</metric>
    <metric>nest-chosen</metric>
    <metric>chosen-nest-discovery</metric>
    <metric>chosen-nest-assessment</metric>
    <metric>chosen-nest-transport</metric>
    <metric>split</metric>
    <metric>nests-found</metric>
    <enumeratedValueSet variable="acceptSD">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="active-ants">
      <value value="55"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="base-accept-threshold">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="brood-percent">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colony-size">
      <value value="13"/>
      <value value="27"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment-base">
      <value value="99.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment-SD">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="count-WF">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffusion-rate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="evaporation-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="feedback-strength">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="good-nests">
      <value value="&quot;single&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="15000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-nests">
      <value value="1"/>
      <value value="2"/>
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nest-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pheromone-deposition">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-dep-commit?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-good-nests">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-bad-nests">
      <value value="40"/>
      <value value="30"/>
      <value value="20"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-stay?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-percent">
      <value value="27"/>
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-SD">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="QT-error?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scout-chance">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence-base">
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence-SD">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transporter-feedback?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-time">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="negative-feedback">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="accept thrs empirical 20170531 8.5" repetitions="50" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count ants</metric>
    <metric>count ants with [transports &gt; 0]</metric>
    <metric>best-nest</metric>
    <metric>result</metric>
    <metric>success</metric>
    <metric>first-nest-discovered</metric>
    <metric>first-discovery-time</metric>
    <metric>nest-chosen</metric>
    <metric>chosen-nest-discovery</metric>
    <metric>chosen-nest-assessment</metric>
    <metric>chosen-nest-transport</metric>
    <metric>split</metric>
    <metric>nests-found</metric>
    <enumeratedValueSet variable="acceptSD">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="active-ants">
      <value value="55"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="base-accept-threshold">
      <value value="50"/>
      <value value="60"/>
      <value value="70"/>
      <value value="80"/>
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="brood-percent">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colony-size">
      <value value="13"/>
      <value value="27"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment-base">
      <value value="99.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment-SD">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="count-WF">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffusion-rate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="evaporation-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="feedback-strength">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="good-nests">
      <value value="&quot;single&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="15000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-nests">
      <value value="1"/>
      <value value="2"/>
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nest-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pheromone-deposition">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-dep-commit?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-good-nests">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-bad-nests">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-stay?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-percent">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-SD">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="QT-error?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scout-chance">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence-base">
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence-SD">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transporter-feedback?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-time">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="negative-feedback">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="9.2.1 template" repetitions="50" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count ants</metric>
    <metric>count ants with [transports &gt; 0]</metric>
    <metric>best-nest</metric>
    <metric>result</metric>
    <metric>success</metric>
    <metric>first-nest-discovered</metric>
    <metric>first-discovery-time</metric>
    <metric>nest-chosen</metric>
    <metric>chosen-nest-discovery</metric>
    <metric>chosen-nest-assessment</metric>
    <metric>chosen-nest-transport</metric>
    <metric>split</metric>
    <metric>nests-found</metric>
    <metric>nests-with-votes</metric>
    <enumeratedValueSet variable="acceptSD">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="active-ants">
      <value value="55"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="base-accept-threshold">
      <value value="50"/>
      <value value="60"/>
      <value value="70"/>
      <value value="80"/>
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="brood-percent">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colony-size">
      <value value="13"/>
      <value value="27"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment-base">
      <value value="99.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment-SD">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="count-WF">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffusion-rate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="evaporation-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="feedback-strength">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="good-nests">
      <value value="&quot;single&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="15000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-nests">
      <value value="1"/>
      <value value="2"/>
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nest-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pheromone-deposition">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-dep-commit?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-good-nests">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-bad-nests">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-stay?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-percent">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-SD">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="QT-error?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scout-chance">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence-base">
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence-SD">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transporter-feedback?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-time">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="negative-feedback">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="9.2.1 acc thrsh with votes" repetitions="50" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count ants</metric>
    <metric>count ants with [transports &gt; 0]</metric>
    <metric>best-nest</metric>
    <metric>result</metric>
    <metric>success</metric>
    <metric>first-nest-discovered</metric>
    <metric>first-discovery-time</metric>
    <metric>nest-chosen</metric>
    <metric>chosen-nest-discovery</metric>
    <metric>chosen-nest-assessment</metric>
    <metric>chosen-nest-transport</metric>
    <metric>split</metric>
    <metric>nests-found</metric>
    <metric>nests-with-votes</metric>
    <metric>chosen-votes</metric>
    <metric>other-votes</metric>
    <enumeratedValueSet variable="acceptSD">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="active-ants">
      <value value="55"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="base-accept-threshold">
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
      <value value="60"/>
      <value value="70"/>
      <value value="80"/>
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="brood-percent">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colony-size">
      <value value="13"/>
      <value value="27"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment-base">
      <value value="99.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="count-WF">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffusion-rate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="evaporation-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="feedback-strength">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="good-nests">
      <value value="&quot;single&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="15000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-nests">
      <value value="1"/>
      <value value="2"/>
      <value value="4"/>
      <value value="8"/>
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nest-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pheromone-deposition">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-good-nests">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-bad-nests">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-stay?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-percent">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="QT-error?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scout-chance">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence-base">
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transporter-feedback?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-time">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="9.2.2 acc thrsh disc 50r" repetitions="50" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count ants</metric>
    <metric>count ants with [transports &gt; 0]</metric>
    <metric>best-nest</metric>
    <metric>result</metric>
    <metric>success</metric>
    <metric>first-nest-discovered</metric>
    <metric>first-discovery-time</metric>
    <metric>nest-chosen</metric>
    <metric>chosen-nest-discovery</metric>
    <metric>chosen-nest-assessment</metric>
    <metric>chosen-nest-transport</metric>
    <metric>split</metric>
    <metric>nests-found</metric>
    <metric>nests-with-votes</metric>
    <metric>chosen-votes</metric>
    <metric>other-votes</metric>
    <enumeratedValueSet variable="acceptSD">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="active-ants">
      <value value="55"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="base-accept-threshold">
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
      <value value="60"/>
      <value value="70"/>
      <value value="80"/>
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="brood-percent">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colony-size">
      <value value="13"/>
      <value value="27"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment-base">
      <value value="99.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="count-WF">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffusion-rate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="evaporation-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="feedback-strength">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="good-nests">
      <value value="&quot;single&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="15000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-nests">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nest-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pheromone-deposition">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-good-nests">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-bad-nests">
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
      <value value="60"/>
      <value value="70"/>
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-stay?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-percent">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="QT-error?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scout-chance">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence-base">
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transporter-feedback?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-time">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="9.2.1 acc thrsh with votes big cols" repetitions="50" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count ants</metric>
    <metric>count ants with [transports &gt; 0]</metric>
    <metric>best-nest</metric>
    <metric>result</metric>
    <metric>success</metric>
    <metric>first-nest-discovered</metric>
    <metric>first-discovery-time</metric>
    <metric>nest-chosen</metric>
    <metric>chosen-nest-discovery</metric>
    <metric>chosen-nest-assessment</metric>
    <metric>chosen-nest-transport</metric>
    <metric>split</metric>
    <metric>nests-found</metric>
    <metric>nests-with-votes</metric>
    <metric>chosen-votes</metric>
    <metric>other-votes</metric>
    <enumeratedValueSet variable="acceptSD">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="active-ants">
      <value value="55"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="base-accept-threshold">
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
      <value value="60"/>
      <value value="70"/>
      <value value="80"/>
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="brood-percent">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colony-size">
      <value value="75"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment-base">
      <value value="99.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="count-WF">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffusion-rate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="evaporation-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="feedback-strength">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="good-nests">
      <value value="&quot;single&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="15000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-nests">
      <value value="1"/>
      <value value="2"/>
      <value value="4"/>
      <value value="8"/>
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nest-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pheromone-deposition">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-good-nests">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-bad-nests">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-stay?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-percent">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="QT-error?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scout-chance">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence-base">
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transporter-feedback?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-time">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="9.2.2 acc thrsh quorum cs 28" repetitions="100" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count ants</metric>
    <metric>count ants with [transports &gt; 0]</metric>
    <metric>best-nest</metric>
    <metric>result</metric>
    <metric>success</metric>
    <metric>first-nest-discovered</metric>
    <metric>first-discovery-time</metric>
    <metric>nest-chosen</metric>
    <metric>chosen-nest-discovery</metric>
    <metric>chosen-nest-assessment</metric>
    <metric>chosen-nest-transport</metric>
    <metric>split</metric>
    <metric>nests-found</metric>
    <metric>nests-with-votes</metric>
    <metric>chosen-votes</metric>
    <metric>other-votes</metric>
    <enumeratedValueSet variable="acceptSD">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="active-ants">
      <value value="55"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="base-accept-threshold">
      <value value="5"/>
      <value value="10"/>
      <value value="15"/>
      <value value="20"/>
      <value value="25"/>
      <value value="30"/>
      <value value="35"/>
      <value value="40"/>
      <value value="45"/>
      <value value="50"/>
      <value value="55"/>
      <value value="60"/>
      <value value="65"/>
      <value value="70"/>
      <value value="75"/>
      <value value="80"/>
      <value value="85"/>
      <value value="90"/>
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="brood-percent">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colony-size">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment-base">
      <value value="99.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="count-WF">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffusion-rate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="evaporation-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="feedback-strength">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="good-nests">
      <value value="&quot;single&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="15000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-nests">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nest-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pheromone-deposition">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-good-nests">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-bad-nests">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-stay?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-percent">
      <value value="20"/>
      <value value="21"/>
      <value value="22"/>
      <value value="23"/>
      <value value="24"/>
      <value value="25"/>
      <value value="26"/>
      <value value="27"/>
      <value value="28"/>
      <value value="29"/>
      <value value="30"/>
      <value value="31"/>
      <value value="32"/>
      <value value="33"/>
      <value value="34"/>
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="QT-error?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scout-chance">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence-base">
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transporter-feedback?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-time">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="9.2.2 acc search cs 28" repetitions="20" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count ants</metric>
    <metric>count ants with [transports &gt; 0]</metric>
    <metric>best-nest</metric>
    <metric>result</metric>
    <metric>success</metric>
    <metric>first-nest-discovered</metric>
    <metric>first-discovery-time</metric>
    <metric>nest-chosen</metric>
    <metric>chosen-nest-discovery</metric>
    <metric>chosen-nest-assessment</metric>
    <metric>chosen-nest-transport</metric>
    <metric>split</metric>
    <metric>nests-found</metric>
    <metric>nests-with-votes</metric>
    <metric>chosen-votes</metric>
    <metric>other-votes</metric>
    <enumeratedValueSet variable="acceptSD">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="active-ants">
      <value value="55"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="base-accept-threshold">
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
      <value value="60"/>
      <value value="70"/>
      <value value="80"/>
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="brood-percent">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colony-size">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment-base">
      <value value="99.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="count-WF">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffusion-rate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="evaporation-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="feedback-strength">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="good-nests">
      <value value="&quot;single&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="15000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-nests">
      <value value="1"/>
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nest-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pheromone-deposition">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-good-nests">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-bad-nests">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-stay?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-percent">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="QT-error?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scout-chance">
      <value value="0.005"/>
      <value value="0.01"/>
      <value value="0.02"/>
      <value value="0.04"/>
      <value value="0.05"/>
      <value value="0.1"/>
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence-base">
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transporter-feedback?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-time">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="9.2.2 acc thrsh quorum cs 16 nests 28" repetitions="100" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count ants</metric>
    <metric>count ants with [transports &gt; 0]</metric>
    <metric>best-nest</metric>
    <metric>result</metric>
    <metric>success</metric>
    <metric>first-nest-discovered</metric>
    <metric>first-discovery-time</metric>
    <metric>nest-chosen</metric>
    <metric>chosen-nest-discovery</metric>
    <metric>chosen-nest-assessment</metric>
    <metric>chosen-nest-transport</metric>
    <metric>split</metric>
    <metric>nests-found</metric>
    <metric>nests-with-votes</metric>
    <metric>chosen-votes</metric>
    <metric>other-votes</metric>
    <enumeratedValueSet variable="acceptSD">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="active-ants">
      <value value="55"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="base-accept-threshold">
      <value value="5"/>
      <value value="10"/>
      <value value="15"/>
      <value value="20"/>
      <value value="25"/>
      <value value="30"/>
      <value value="35"/>
      <value value="40"/>
      <value value="45"/>
      <value value="50"/>
      <value value="55"/>
      <value value="60"/>
      <value value="65"/>
      <value value="70"/>
      <value value="75"/>
      <value value="80"/>
      <value value="85"/>
      <value value="90"/>
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="brood-percent">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colony-size">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment-base">
      <value value="99.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="count-WF">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffusion-rate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="evaporation-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="feedback-strength">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="good-nests">
      <value value="&quot;single&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="15000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-nests">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nest-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pheromone-deposition">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-good-nests">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-bad-nests">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-stay?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-percent">
      <value value="20"/>
      <value value="21"/>
      <value value="22"/>
      <value value="23"/>
      <value value="24"/>
      <value value="25"/>
      <value value="26"/>
      <value value="27"/>
      <value value="28"/>
      <value value="29"/>
      <value value="30"/>
      <value value="31"/>
      <value value="32"/>
      <value value="33"/>
      <value value="34"/>
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="QT-error?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scout-chance">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence-base">
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transporter-feedback?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-time">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="9.2.2 acc search cs 28" repetitions="100" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count ants</metric>
    <metric>count ants with [transports &gt; 0]</metric>
    <metric>best-nest</metric>
    <metric>result</metric>
    <metric>success</metric>
    <metric>first-nest-discovered</metric>
    <metric>first-discovery-time</metric>
    <metric>nest-chosen</metric>
    <metric>chosen-nest-discovery</metric>
    <metric>chosen-nest-assessment</metric>
    <metric>chosen-nest-transport</metric>
    <metric>split</metric>
    <metric>nests-found</metric>
    <metric>nests-with-votes</metric>
    <metric>chosen-votes</metric>
    <metric>other-votes</metric>
    <enumeratedValueSet variable="acceptSD">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="active-ants">
      <value value="55"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="base-accept-threshold">
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
      <value value="60"/>
      <value value="70"/>
      <value value="80"/>
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="brood-percent">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colony-size">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment-base">
      <value value="99.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="count-WF">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffusion-rate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="evaporation-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="feedback-strength">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="good-nests">
      <value value="&quot;single&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="15000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-nests">
      <value value="1"/>
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nest-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pheromone-deposition">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-good-nests">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-bad-nests">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-stay?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-percent">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="QT-error?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scout-chance">
      <value value="0.005"/>
      <value value="0.01"/>
      <value value="0.05"/>
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence-base">
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transporter-feedback?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-time">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="9.2.2 acc thrsh  cs 1 nest" repetitions="100" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count ants</metric>
    <metric>count ants with [transports &gt; 0]</metric>
    <metric>best-nest</metric>
    <metric>result</metric>
    <metric>success</metric>
    <metric>first-nest-discovered</metric>
    <metric>first-discovery-time</metric>
    <metric>nest-chosen</metric>
    <metric>chosen-nest-discovery</metric>
    <metric>chosen-nest-assessment</metric>
    <metric>chosen-nest-transport</metric>
    <metric>split</metric>
    <metric>nests-found</metric>
    <metric>nests-with-votes</metric>
    <metric>chosen-votes</metric>
    <metric>other-votes</metric>
    <enumeratedValueSet variable="acceptSD">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="active-ants">
      <value value="55"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="base-accept-threshold">
      <value value="5"/>
      <value value="10"/>
      <value value="15"/>
      <value value="20"/>
      <value value="25"/>
      <value value="30"/>
      <value value="35"/>
      <value value="40"/>
      <value value="45"/>
      <value value="50"/>
      <value value="55"/>
      <value value="60"/>
      <value value="65"/>
      <value value="70"/>
      <value value="75"/>
      <value value="80"/>
      <value value="85"/>
      <value value="90"/>
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="brood-percent">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colony-size">
      <value value="5"/>
      <value value="10"/>
      <value value="15"/>
      <value value="20"/>
      <value value="25"/>
      <value value="30"/>
      <value value="35"/>
      <value value="40"/>
      <value value="45"/>
      <value value="50"/>
      <value value="55"/>
      <value value="60"/>
      <value value="65"/>
      <value value="70"/>
      <value value="75"/>
      <value value="80"/>
      <value value="85"/>
      <value value="90"/>
      <value value="95"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment-base">
      <value value="99.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="count-WF">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffusion-rate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="evaporation-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="feedback-strength">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="good-nests">
      <value value="&quot;single&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="15000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-nests">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nest-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pheromone-deposition">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-good-nests">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-bad-nests">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-stay?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-percent">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="QT-error?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scout-chance">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence-base">
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transporter-feedback?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-time">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="9.2.2 acc 80 cs speed 10 reps nests 1 2" repetitions="10" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count ants</metric>
    <metric>count ants with [transports &gt; 0]</metric>
    <metric>best-nest</metric>
    <metric>result</metric>
    <metric>success</metric>
    <metric>first-nest-discovered</metric>
    <metric>first-discovery-time</metric>
    <metric>nest-chosen</metric>
    <metric>chosen-nest-discovery</metric>
    <metric>chosen-nest-assessment</metric>
    <metric>chosen-nest-transport</metric>
    <metric>split</metric>
    <metric>nests-found</metric>
    <metric>nests-with-votes</metric>
    <metric>chosen-votes</metric>
    <metric>other-votes</metric>
    <enumeratedValueSet variable="acceptSD">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="active-ants">
      <value value="55"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="base-accept-threshold">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="brood-percent">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colony-size">
      <value value="5"/>
      <value value="10"/>
      <value value="15"/>
      <value value="20"/>
      <value value="25"/>
      <value value="30"/>
      <value value="35"/>
      <value value="40"/>
      <value value="45"/>
      <value value="50"/>
      <value value="55"/>
      <value value="60"/>
      <value value="65"/>
      <value value="70"/>
      <value value="75"/>
      <value value="80"/>
      <value value="85"/>
      <value value="90"/>
      <value value="95"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment-base">
      <value value="99.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="count-WF">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffusion-rate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="evaporation-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="feedback-strength">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="good-nests">
      <value value="&quot;single&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="15000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-speed">
      <value value="1"/>
      <value value="1.2"/>
      <value value="1.5"/>
      <value value="2"/>
      <value value="3"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-nests">
      <value value="1"/>
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nest-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pheromone-deposition">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-good-nests">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-bad-nests">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-stay?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-percent">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="QT-error?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scout-chance">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence-base">
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transporter-feedback?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-time">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="9.2.2 acc thrsh  cs 16 nest half 65 reps" repetitions="65" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count ants</metric>
    <metric>count ants with [transports &gt; 0]</metric>
    <metric>best-nest</metric>
    <metric>result</metric>
    <metric>success</metric>
    <metric>first-nest-discovered</metric>
    <metric>first-discovery-time</metric>
    <metric>nest-chosen</metric>
    <metric>chosen-nest-discovery</metric>
    <metric>chosen-nest-assessment</metric>
    <metric>chosen-nest-transport</metric>
    <metric>split</metric>
    <metric>nests-found</metric>
    <metric>nests-with-votes</metric>
    <metric>chosen-votes</metric>
    <metric>other-votes</metric>
    <enumeratedValueSet variable="acceptSD">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="active-ants">
      <value value="55"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="base-accept-threshold">
      <value value="5"/>
      <value value="10"/>
      <value value="15"/>
      <value value="20"/>
      <value value="25"/>
      <value value="30"/>
      <value value="35"/>
      <value value="40"/>
      <value value="45"/>
      <value value="50"/>
      <value value="55"/>
      <value value="60"/>
      <value value="65"/>
      <value value="70"/>
      <value value="75"/>
      <value value="80"/>
      <value value="85"/>
      <value value="90"/>
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="brood-percent">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colony-size">
      <value value="5"/>
      <value value="10"/>
      <value value="15"/>
      <value value="20"/>
      <value value="25"/>
      <value value="30"/>
      <value value="35"/>
      <value value="40"/>
      <value value="45"/>
      <value value="50"/>
      <value value="55"/>
      <value value="60"/>
      <value value="65"/>
      <value value="70"/>
      <value value="75"/>
      <value value="80"/>
      <value value="85"/>
      <value value="90"/>
      <value value="95"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment-base">
      <value value="99.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="count-WF">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffusion-rate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="evaporation-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="feedback-strength">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="good-nests">
      <value value="&quot;half&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="15000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-nests">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nest-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pheromone-deposition">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-good-nests">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-bad-nests">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-stay?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-percent">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="QT-error?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scout-chance">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence-base">
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transporter-feedback?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-time">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="9.2.2 acc thrsh  trailinf 10 reps vlow vals" repetitions="10" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count ants</metric>
    <metric>count ants with [transports &gt; 0]</metric>
    <metric>best-nest</metric>
    <metric>result</metric>
    <metric>success</metric>
    <metric>first-nest-discovered</metric>
    <metric>first-discovery-time</metric>
    <metric>nest-chosen</metric>
    <metric>chosen-nest-discovery</metric>
    <metric>chosen-nest-assessment</metric>
    <metric>chosen-nest-transport</metric>
    <metric>split</metric>
    <metric>nests-found</metric>
    <metric>nests-with-votes</metric>
    <metric>chosen-votes</metric>
    <metric>other-votes</metric>
    <enumeratedValueSet variable="acceptSD">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="active-ants">
      <value value="55"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="base-accept-threshold">
      <value value="5"/>
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
      <value value="60"/>
      <value value="70"/>
      <value value="80"/>
      <value value="90"/>
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="brood-percent">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colony-size">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment-base">
      <value value="99.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="count-WF">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffusion-rate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="evaporation-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="feedback-strength">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="good-nests">
      <value value="&quot;single&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="15000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-nests">
      <value value="1"/>
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nest-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pheromone-deposition">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-good-nests">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-bad-nests">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-stay?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-percent">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="QT-error?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scout-chance">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence-base">
      <value value="0"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transporter-feedback?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-time">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="9.2.2 acc thrsh  commit 10 reps" repetitions="10" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count ants</metric>
    <metric>count ants with [transports &gt; 0]</metric>
    <metric>best-nest</metric>
    <metric>result</metric>
    <metric>success</metric>
    <metric>first-nest-discovered</metric>
    <metric>first-discovery-time</metric>
    <metric>nest-chosen</metric>
    <metric>chosen-nest-discovery</metric>
    <metric>chosen-nest-assessment</metric>
    <metric>chosen-nest-transport</metric>
    <metric>split</metric>
    <metric>nests-found</metric>
    <metric>nests-with-votes</metric>
    <metric>chosen-votes</metric>
    <metric>other-votes</metric>
    <enumeratedValueSet variable="acceptSD">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="active-ants">
      <value value="55"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="base-accept-threshold">
      <value value="5"/>
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
      <value value="60"/>
      <value value="70"/>
      <value value="80"/>
      <value value="90"/>
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="brood-percent">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colony-size">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment-base">
      <value value="80"/>
      <value value="85"/>
      <value value="90"/>
      <value value="95"/>
      <value value="98"/>
      <value value="99"/>
      <value value="99.3"/>
      <value value="99.5"/>
      <value value="99.7"/>
      <value value="99.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="count-WF">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffusion-rate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="evaporation-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="feedback-strength">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="good-nests">
      <value value="&quot;single&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="15000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-nests">
      <value value="1"/>
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nest-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pheromone-deposition">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-good-nests">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-bad-nests">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-stay?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-percent">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="QT-error?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scout-chance">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence-base">
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transporter-feedback?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-time">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="9.3 accept quorum extra 50 reps" repetitions="50" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count ants</metric>
    <metric>count ants with [transports &gt; 0]</metric>
    <metric>best-nest</metric>
    <metric>result</metric>
    <metric>success</metric>
    <metric>first-nest-discovered</metric>
    <metric>first-discovery-time</metric>
    <metric>nest-chosen</metric>
    <metric>chosen-nest-discovery</metric>
    <metric>chosen-nest-assessment</metric>
    <metric>chosen-nest-transport</metric>
    <metric>split</metric>
    <metric>nests-found</metric>
    <metric>nests-with-votes</metric>
    <metric>chosen-votes</metric>
    <metric>other-votes</metric>
    <enumeratedValueSet variable="QT-error?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pheromone-deposition">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-stay?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-nests">
      <value value="1"/>
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="good-nests">
      <value value="&quot;half&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="brood-percent">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-time">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence-base">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scout-chance">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffusion-rate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="15000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="evaporation-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nest-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="base-accept-threshold">
      <value value="5"/>
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
      <value value="60"/>
      <value value="70"/>
      <value value="80"/>
      <value value="90"/>
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-bad-nests">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="switch-point">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-environment?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-good-nests">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="acceptSD">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment-base">
      <value value="99.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-percent">
      <value value="5"/>
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
      <value value="60"/>
      <value value="70"/>
      <value value="80"/>
      <value value="90"/>
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="count-WF">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colony-size">
      <value value="30"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="9.3 accept quorum 4 8 16 100 reps" repetitions="100" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count ants</metric>
    <metric>count ants with [transports &gt; 0]</metric>
    <metric>best-nest</metric>
    <metric>result</metric>
    <metric>success</metric>
    <metric>first-nest-discovered</metric>
    <metric>first-discovery-time</metric>
    <metric>nest-chosen</metric>
    <metric>chosen-nest-discovery</metric>
    <metric>chosen-nest-assessment</metric>
    <metric>chosen-nest-transport</metric>
    <metric>split</metric>
    <metric>nests-found</metric>
    <metric>nests-with-votes</metric>
    <metric>chosen-votes</metric>
    <metric>other-votes</metric>
    <enumeratedValueSet variable="QT-error?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pheromone-deposition">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-stay?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-nests">
      <value value="4"/>
      <value value="8"/>
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="good-nests">
      <value value="&quot;half&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="brood-percent">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-time">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence-base">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scout-chance">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffusion-rate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="15000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="evaporation-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nest-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="base-accept-threshold">
      <value value="5"/>
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
      <value value="60"/>
      <value value="70"/>
      <value value="80"/>
      <value value="90"/>
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-bad-nests">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="switch-point">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-environment?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-good-nests">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="acceptSD">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment-base">
      <value value="99.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-percent">
      <value value="5"/>
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
      <value value="60"/>
      <value value="70"/>
      <value value="80"/>
      <value value="90"/>
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="count-WF">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colony-size">
      <value value="30"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="9.3 base pars dynamic" repetitions="100" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count ants</metric>
    <metric>count ants with [transports &gt; 0]</metric>
    <metric>best-nest</metric>
    <metric>result</metric>
    <metric>success</metric>
    <metric>first-nest-discovered</metric>
    <metric>first-discovery-time</metric>
    <metric>nest-chosen</metric>
    <metric>chosen-nest-discovery</metric>
    <metric>chosen-nest-assessment</metric>
    <metric>chosen-nest-transport</metric>
    <metric>split</metric>
    <metric>nests-found</metric>
    <metric>nests-with-votes</metric>
    <metric>chosen-votes</metric>
    <metric>other-votes</metric>
    <enumeratedValueSet variable="QT-error?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pheromone-deposition">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-stay?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-nests">
      <value value="2"/>
      <value value="4"/>
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="good-nests">
      <value value="&quot;single&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="brood-percent">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-time">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence-base">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scout-chance">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffusion-rate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="15000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="evaporation-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nest-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="base-accept-threshold">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-bad-nests">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="switch-point">
      <value value="10"/>
      <value value="50"/>
      <value value="100"/>
      <value value="200"/>
      <value value="400"/>
      <value value="600"/>
      <value value="800"/>
      <value value="1000"/>
      <value value="1200"/>
      <value value="1500"/>
      <value value="2000"/>
      <value value="2500"/>
      <value value="3000"/>
      <value value="5000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-environment?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-good-nests">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="acceptSD">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment-base">
      <value value="99.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-percent">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="count-WF">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colony-size">
      <value value="30"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="9.3 base pars with scout tracking" repetitions="100" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count ants</metric>
    <metric>count ants with [transports &gt; 0]</metric>
    <metric>best-nest</metric>
    <metric>result</metric>
    <metric>success</metric>
    <metric>first-nest-discovered</metric>
    <metric>first-discovery-time</metric>
    <metric>nest-chosen</metric>
    <metric>chosen-nest-discovery</metric>
    <metric>chosen-nest-assessment</metric>
    <metric>chosen-nest-transport</metric>
    <metric>split</metric>
    <metric>nests-found</metric>
    <metric>nests-with-votes</metric>
    <metric>chosen-votes</metric>
    <metric>other-votes</metric>
    <metric>scouts</metric>
    <enumeratedValueSet variable="QT-error?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pheromone-deposition">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-stay?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-nests">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="good-nests">
      <value value="&quot;single&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="brood-percent">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-time">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence-base">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scout-chance">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffusion-rate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="15000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="evaporation-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nest-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="base-accept-threshold">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-bad-nests">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="switch-point">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-environment?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-good-nests">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="acceptSD">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment-base">
      <value value="99.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-percent">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="count-WF">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colony-size">
      <value value="8"/>
      <value value="8"/>
      <value value="8"/>
      <value value="12"/>
      <value value="12"/>
      <value value="13"/>
      <value value="15"/>
      <value value="20"/>
      <value value="21"/>
      <value value="21"/>
      <value value="21"/>
      <value value="25"/>
      <value value="26"/>
      <value value="26"/>
      <value value="27"/>
      <value value="28"/>
      <value value="28"/>
      <value value="29"/>
      <value value="29"/>
      <value value="30"/>
      <value value="30"/>
      <value value="31"/>
      <value value="32"/>
      <value value="33"/>
      <value value="34"/>
      <value value="35"/>
      <value value="36"/>
      <value value="38"/>
      <value value="40"/>
      <value value="41"/>
      <value value="44"/>
      <value value="45"/>
      <value value="46"/>
      <value value="61"/>
      <value value="73"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="9.3.2 accept quorum q28" repetitions="100" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count ants</metric>
    <metric>count ants with [transports &gt; 0]</metric>
    <metric>best-nest</metric>
    <metric>result</metric>
    <metric>success</metric>
    <metric>first-nest-discovered</metric>
    <metric>first-discovery-time</metric>
    <metric>nest-chosen</metric>
    <metric>chosen-nest-discovery</metric>
    <metric>chosen-nest-assessment</metric>
    <metric>chosen-nest-transport</metric>
    <metric>split</metric>
    <metric>nests-found</metric>
    <metric>nests-with-votes</metric>
    <metric>chosen-votes</metric>
    <metric>other-votes</metric>
    <metric>scouts</metric>
    <enumeratedValueSet variable="QT-error?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pheromone-deposition">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-stay?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-nests">
      <value value="1"/>
      <value value="2"/>
      <value value="4"/>
      <value value="8"/>
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="good-nests">
      <value value="&quot;single&quot;"/>
      <value value="&quot;half&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="brood-percent">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-time">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence-base">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scout-chance">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffusion-rate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="15000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="evaporation-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nest-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="base-accept-threshold">
      <value value="5"/>
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
      <value value="60"/>
      <value value="70"/>
      <value value="80"/>
      <value value="90"/>
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-bad-nests">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="switch-point">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-environment?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-good-nests">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="acceptSD">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment-base">
      <value value="99.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-percent">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="count-WF">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colony-size">
      <value value="30"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="9.3.2 search with scout tracking" repetitions="100" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count ants</metric>
    <metric>count ants with [transports &gt; 0]</metric>
    <metric>best-nest</metric>
    <metric>result</metric>
    <metric>success</metric>
    <metric>first-nest-discovered</metric>
    <metric>first-discovery-time</metric>
    <metric>nest-chosen</metric>
    <metric>chosen-nest-discovery</metric>
    <metric>chosen-nest-assessment</metric>
    <metric>chosen-nest-transport</metric>
    <metric>split</metric>
    <metric>nests-found</metric>
    <metric>nests-with-votes</metric>
    <metric>chosen-votes</metric>
    <metric>other-votes</metric>
    <metric>scouts</metric>
    <enumeratedValueSet variable="QT-error?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pheromone-deposition">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-stay?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-nests">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="good-nests">
      <value value="&quot;single&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="brood-percent">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-time">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence-base">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scout-chance">
      <value value="0.1"/>
      <value value="1"/>
      <value value="5"/>
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
      <value value="60"/>
      <value value="70"/>
      <value value="80"/>
      <value value="90"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffusion-rate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="15000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="evaporation-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nest-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="base-accept-threshold">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-bad-nests">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="switch-point">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-environment?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-good-nests">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="acceptSD">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment-base">
      <value value="99.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-percent">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="count-WF">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colony-size">
      <value value="30"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="9.3.2 accept dynamic env cs30 2nest" repetitions="100" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count ants</metric>
    <metric>count ants with [transports &gt; 0]</metric>
    <metric>best-nest</metric>
    <metric>result</metric>
    <metric>success</metric>
    <metric>first-nest-discovered</metric>
    <metric>first-discovery-time</metric>
    <metric>nest-chosen</metric>
    <metric>chosen-nest-discovery</metric>
    <metric>chosen-nest-assessment</metric>
    <metric>chosen-nest-transport</metric>
    <metric>split</metric>
    <metric>nests-found</metric>
    <metric>nests-with-votes</metric>
    <metric>chosen-votes</metric>
    <metric>other-votes</metric>
    <metric>scouts</metric>
    <enumeratedValueSet variable="QT-error?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pheromone-deposition">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-stay?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-nests">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="good-nests">
      <value value="&quot;single&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="brood-percent">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-time">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence-base">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scout-chance">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffusion-rate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="15000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="evaporation-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nest-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="base-accept-threshold">
      <value value="5"/>
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
      <value value="60"/>
      <value value="70"/>
      <value value="80"/>
      <value value="90"/>
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-bad-nests">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="switch-point">
      <value value="10"/>
      <value value="50"/>
      <value value="100"/>
      <value value="200"/>
      <value value="400"/>
      <value value="600"/>
      <value value="800"/>
      <value value="1000"/>
      <value value="1200"/>
      <value value="1500"/>
      <value value="2000"/>
      <value value="2500"/>
      <value value="3000"/>
      <value value="3500"/>
      <value value="4000"/>
      <value value="4500"/>
      <value value="5000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-environment?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-good-nests">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="acceptSD">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment-base">
      <value value="99.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-percent">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="count-WF">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colony-size">
      <value value="30"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="9.3.2 quorum dynamic env cs30 2nest" repetitions="100" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count ants</metric>
    <metric>count ants with [transports &gt; 0]</metric>
    <metric>best-nest</metric>
    <metric>result</metric>
    <metric>success</metric>
    <metric>first-nest-discovered</metric>
    <metric>first-discovery-time</metric>
    <metric>nest-chosen</metric>
    <metric>chosen-nest-discovery</metric>
    <metric>chosen-nest-assessment</metric>
    <metric>chosen-nest-transport</metric>
    <metric>split</metric>
    <metric>nests-found</metric>
    <metric>nests-with-votes</metric>
    <metric>chosen-votes</metric>
    <metric>other-votes</metric>
    <metric>scouts</metric>
    <enumeratedValueSet variable="QT-error?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pheromone-deposition">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-stay?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-nests">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="good-nests">
      <value value="&quot;single&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="brood-percent">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-time">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence-base">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scout-chance">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffusion-rate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="15000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="evaporation-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nest-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="base-accept-threshold">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-bad-nests">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="switch-point">
      <value value="10"/>
      <value value="50"/>
      <value value="100"/>
      <value value="200"/>
      <value value="400"/>
      <value value="600"/>
      <value value="800"/>
      <value value="1000"/>
      <value value="1200"/>
      <value value="1500"/>
      <value value="2000"/>
      <value value="2500"/>
      <value value="3000"/>
      <value value="3500"/>
      <value value="4000"/>
      <value value="4500"/>
      <value value="5000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-environment?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-good-nests">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="acceptSD">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment-base">
      <value value="99.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-percent">
      <value value="5"/>
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
      <value value="60"/>
      <value value="70"/>
      <value value="80"/>
      <value value="90"/>
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="count-WF">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colony-size">
      <value value="30"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="9.3.2 quorum discrimination base pars" repetitions="100" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count ants</metric>
    <metric>count ants with [transports &gt; 0]</metric>
    <metric>best-nest</metric>
    <metric>result</metric>
    <metric>success</metric>
    <metric>first-nest-discovered</metric>
    <metric>first-discovery-time</metric>
    <metric>nest-chosen</metric>
    <metric>chosen-nest-discovery</metric>
    <metric>chosen-nest-assessment</metric>
    <metric>chosen-nest-transport</metric>
    <metric>split</metric>
    <metric>nests-found</metric>
    <metric>nests-with-votes</metric>
    <metric>chosen-votes</metric>
    <metric>other-votes</metric>
    <metric>scouts</metric>
    <enumeratedValueSet variable="QT-error?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pheromone-deposition">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-stay?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-nests">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="good-nests">
      <value value="&quot;single&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="brood-percent">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-time">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence-base">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scout-chance">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffusion-rate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="15000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="evaporation-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nest-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="base-accept-threshold">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-bad-nests">
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
      <value value="60"/>
      <value value="70"/>
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="switch-point">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-environment?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-good-nests">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="acceptSD">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment-base">
      <value value="99.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-percent">
      <value value="5"/>
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
      <value value="60"/>
      <value value="70"/>
      <value value="80"/>
      <value value="90"/>
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="count-WF">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colony-size">
      <value value="30"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="col21 sim 5" repetitions="5" sequentialRunOrder="false" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count ants</metric>
    <metric>count ants with [transports &gt; 0]</metric>
    <metric>best-nest</metric>
    <metric>result</metric>
    <metric>success</metric>
    <metric>first-nest-discovered</metric>
    <metric>first-discovery-time</metric>
    <metric>nest-chosen</metric>
    <metric>chosen-nest-discovery</metric>
    <metric>chosen-nest-assessment</metric>
    <metric>chosen-nest-transport</metric>
    <metric>split</metric>
    <metric>nests-found</metric>
    <metric>nests-with-votes</metric>
    <metric>chosen-votes</metric>
    <metric>other-votes</metric>
    <metric>scouts</metric>
    <enumeratedValueSet variable="QT-error?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pheromone-deposition">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-stay?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-nests">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="good-nests">
      <value value="&quot;single&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="brood-percent">
      <value value="86"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-time">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence-base">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scout-chance">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffusion-rate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="15000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="evaporation-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nest-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="base-accept-threshold">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-bad-nests">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="switch-point">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-environment?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-good-nests">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="acceptSD">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment-base">
      <value value="99.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-percent">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="count-WF">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colony-size">
      <value value="44"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="9.3.2 WOC expt2 replication" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count ants</metric>
    <metric>count ants with [transports &gt; 0]</metric>
    <metric>best-nest</metric>
    <metric>result</metric>
    <metric>success</metric>
    <metric>first-nest-discovered</metric>
    <metric>first-discovery-time</metric>
    <metric>nest-chosen</metric>
    <metric>chosen-nest-discovery</metric>
    <metric>chosen-nest-assessment</metric>
    <metric>chosen-nest-transport</metric>
    <metric>split</metric>
    <metric>nests-found</metric>
    <metric>nests-with-votes</metric>
    <metric>chosen-votes</metric>
    <metric>other-votes</metric>
    <metric>scouts</metric>
    <enumeratedValueSet variable="QT-error?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pheromone-deposition">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-stay?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-nests">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="good-nests">
      <value value="&quot;single&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="brood-percent">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-time">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence-base">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scout-chance">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffusion-rate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="15000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="evaporation-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nest-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="base-accept-threshold">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-bad-nests">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="switch-point">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-environment?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-good-nests">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="acceptSD">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment-base">
      <value value="99.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-percent">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="count-WF">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colony-size">
      <value value="5"/>
      <value value="6"/>
      <value value="7"/>
      <value value="8"/>
      <value value="8"/>
      <value value="8"/>
      <value value="8"/>
      <value value="10"/>
      <value value="10"/>
      <value value="10"/>
      <value value="10"/>
      <value value="11"/>
      <value value="12"/>
      <value value="12"/>
      <value value="13"/>
      <value value="14"/>
      <value value="15"/>
      <value value="16"/>
      <value value="17"/>
      <value value="17"/>
      <value value="18"/>
      <value value="18"/>
      <value value="20"/>
      <value value="20"/>
      <value value="20"/>
      <value value="20"/>
      <value value="21"/>
      <value value="23"/>
      <value value="23"/>
      <value value="24"/>
      <value value="25"/>
      <value value="26"/>
      <value value="27"/>
      <value value="27"/>
      <value value="27"/>
      <value value="27"/>
      <value value="27"/>
      <value value="30"/>
      <value value="30"/>
      <value value="30"/>
      <value value="31"/>
      <value value="33"/>
      <value value="34"/>
      <value value="34"/>
      <value value="34"/>
      <value value="35"/>
      <value value="35"/>
      <value value="36"/>
      <value value="37"/>
      <value value="37"/>
      <value value="38"/>
      <value value="39"/>
      <value value="41"/>
      <value value="43"/>
      <value value="44"/>
      <value value="45"/>
      <value value="46"/>
      <value value="48"/>
      <value value="48"/>
      <value value="50"/>
      <value value="51"/>
      <value value="57"/>
      <value value="58"/>
      <value value="60"/>
      <value value="61"/>
      <value value="61"/>
      <value value="64"/>
      <value value="69"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="9.3.2.1 Poisson accept" repetitions="10" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count ants</metric>
    <metric>count ants with [transports &gt; 0]</metric>
    <metric>best-nest</metric>
    <metric>result</metric>
    <metric>success</metric>
    <metric>first-nest-discovered</metric>
    <metric>first-discovery-time</metric>
    <metric>nest-chosen</metric>
    <metric>chosen-nest-discovery</metric>
    <metric>chosen-nest-assessment</metric>
    <metric>chosen-nest-transport</metric>
    <metric>split</metric>
    <metric>nests-found</metric>
    <metric>nests-with-votes</metric>
    <metric>chosen-votes</metric>
    <metric>other-votes</metric>
    <metric>scouts</metric>
    <enumeratedValueSet variable="QT-error?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pheromone-deposition">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-stay?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-nests">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="good-nests">
      <value value="&quot;single&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="brood-percent">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wait-time">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trail-influence-base">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scout-chance">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffusion-rate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="15000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="evaporation-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nest-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="base-accept-threshold">
      <value value="5"/>
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
      <value value="60"/>
      <value value="70"/>
      <value value="80"/>
      <value value="90"/>
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-bad-nests">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="switch-point">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-environment?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quality-good-nests">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="acceptSD">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="commitment-base">
      <value value="99.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quorum-percent">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="count-WF">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colony-size">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="accept-distribution">
      <value value="&quot;Poisson&quot;"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
