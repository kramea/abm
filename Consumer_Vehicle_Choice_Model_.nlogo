;; This model runs the network of houses, workplaces and public locations in a neighborhood
;; and finds the average purchase probability of three vehicle technologies in the population

;; Different breeds of turtles are initialized to keep track of various locations and objects in the model
;; Vehicles move from one location to another and they also have their own variables which is used to calculate
;; the purchase probability of vehicle technologies
breed [ houses house]
breed [ works work]
breed [ place2s place2 ]
breed [ place3s place3 ]
breed [ place4s place4 ]
breed [vehicles vehicle]
patches-own [hcharge? wcharge? pcharge? h2? ] ;; each patch location stores recharge variables and hydrogen station location variables
vehicles-own [homelocation wlocation range income bevdisutil convdisutil fcvdisutil fcvrange]
globals [dist] ;; this global variable stores the link distances during calculation


;; the setup procedure initializes the locations, vehicles and attributes
;; one household has one vehicle, and there is only one turtle per patch
to setup
  clear-all

  ask patches [ set pcolor white ] ;; blank background

  ;; patches are colored differently to make sure there is only one type of location per patch and not duplicated
  ask n-of (num-population + 50) patches [ set pcolor 8 ]
  ask n-of ((share-workplaces * num-population) + 10) patches [ set pcolor 9 ]
  ask n-of ( (num-population * 0.1 + public-chargingstations) + 10 ) patches [ set pcolor 9.5 ]
  ask n-of ( (num-population * 0.1 + public-chargingstations) + 10) patches [ set pcolor 9.6 ]
  ask n-of ((num-population * 0.1 + public-chargingstations) + 10) patches [ set pcolor 9.7 ]

  ask n-of (num-population) patches with [pcolor = 8 ][sprout-houses 1 [
     set color red
     set shape "house"]
  ]
  ask n-of (num-population ) patches with [pcolor = 8 and any? other houses-here][sprout-vehicles 1 [
     set color yellow
     ask vehicles with [any? houses-here] [set homelocation one-of houses-here] ;; the vehicle chooses the homelocation here
     set shape "car"]
  ]
  ask n-of (share-workplaces * num-population) patches with [pcolor = 9 and not any? other works-here][sprout-works 1 [
     set color blue
     set shape "triangle"]
  ]

  ask n-of ((num-population * 0.1) + public-chargingstations) patches with [pcolor = 9.5 and not any? other place2s-here][sprout-place2s 1 [
     set color 25
     set shape "triangle"]
  ]

  ask n-of ((num-population * 0.1) + public-chargingstations) patches with [pcolor = 9.6 and not any? other place3s-here][sprout-place3s 1 [
     set color 26
     set shape "triangle"]
  ]

  ask n-of ((num-population * 0.1) + public-chargingstations) patches with [pcolor = 9.7 and not any? other place4s-here][sprout-place4s 1 [
     set color 27
     set shape "triangle"]
  ]

  ask n-of (num-population * homecharge-share) patches with [pcolor = 8 and any? houses-here] [ set hcharge? 1]
  ask n-of (num-population * (1 - homecharge-share)) patches with [pcolor = 8 and any? houses-here] [ set hcharge? 0]

  ask n-of (num-population * share-workplaces * workcharge-share) patches with [pcolor = 9 and any? works-here] [ set wcharge? 1]
  ask n-of (num-population * share-workplaces * (1 - workcharge-share)) patches with [pcolor = 9 and any? works-here] [ set wcharge? 0]

  ask n-of (public-chargingstations * 0.3) patches with [pcolor = 9.5 and any? place2s-here] [ set pcharge? 1 set pcolor violet]

  ask n-of (public-chargingstations * 0.3) patches with [pcolor = 9.6 and any? place3s-here] [ set pcharge? 1 set pcolor violet]

  ask n-of (public-chargingstations * 0.3) patches with [pcolor = 9.7 and any? place4s-here] [ set pcharge? 1 set pcolor violet]

  ask n-of (h2-stations) patches with [pcolor = white] [ set h2? 1 set pcolor 67]

  ;; the following routine creates links between houses and workplaces and other public locations
  ask  houses
  [
    If any? works [ create-link-with one-of works ]
    if any? place2s [ create-link-with one-of place2s ]
    if any? place3s [ create-link-with one-of place3s ]
    if any? place4s [ create-link-with one-of place4s ]
  ]

  ask vehicles [
    if any? patches with [hcharge? = 1] [ set range range + 42] ;; if the house has recharging availability, 42 miles are added here
    ;; the 42 electric mile range comes from 8 hours of recharging * 6 kW power
    ]

  ask vehicles [set wlocation one-of [link-neighbors with [color = blue]] of homelocation] ;; vehicle chooses the worklocation here

  ask patches with [pcolor != violet  and pcolor != 67 ] [set pcolor white]

  ask links [ set color 9.3]

  ask vehicles [
    if (count other patches with [pcolor = 67] in-radius 5  > 0 )[ set fcvrange fcvrange + 250]
    ;; if there is hydrogen station available, the model adds 250 miles to the vehicle range
    ]

  ;; based on the input shares, income categories are created
  ;; the vehicle price / income share is used to add the various disutility levels
  ;; These are 2016 vehicle prices from Department of Energy
  ;; Gasoline vehicle price = $20,280
  ;; Battery electric vehicle price = $31,086
  ;; Fuel cell vehicle price = $33,252
  ask n-of (num-population *  income-morethan125K )  vehicles  [
    set bevdisutil  ( 31086 / 125000 ) * 2500  ; vehicle price / income
    set fcvdisutil  ( 33252 / 125000 ) * 2500
    set convdisutil  ( 20280 / 125000 ) * 2500
    set income 125000
     ] ; high-income
  ask n-of (num-population *  income-75to125K ) vehicles with [income = 0 ] [
    set bevdisutil  ( 31086 / 100000 ) * 2500
    set fcvdisutil  ( 33252 / 100000 ) * 2500
    set convdisutil  ( 20280 / 100000 ) * 2500
    set income 100000
     ] ; upper-med-income
  ask n-of (num-population *  income-30to75K ) vehicles with [ income = 0 ] [
    set bevdisutil  ( 31086 / 50000 ) * 2500
    set fcvdisutil  ( 33252 / 50000 ) * 2500
    set convdisutil  ( 20280 / 50000 ) * 2500
    set income 50000
     ] ; lower-med-income

 ask n-of (num-population *  income-lessthan30K ) vehicles with [ income = 0 ]  [
    set bevdisutil  ( 31086 / 25000 ) * 2500
    set fcvdisutil  ( 33252 / 25000 ) * 2500
    set convdisutil  ( 20280 / 25000 ) * 2500
    set income 25000
     ] ; lower-income

  reset-ticks
end

;; This routine retains the link network
;; and restores the utility levels back to the start of the run
to wipe
  reset-ticks
  clear-plot
  ask vehicles [
    move-to homelocation
     if (count other patches with [pcolor = 67] in-radius 5  > 0 )[ set fcvrange 250]
     if any? patches with [hcharge? = 1] [ set range 42]
     set bevdisutil  ( 31086 / income ) * 2500
     set fcvdisutil  ( 33252 / income ) * 2500
     set convdisutil  ( 20280 / income ) * 2500
    ]

end


;; the go procedure moves the vehicle from one location to another
;; and calculates the distance related disutility costs along the way
to go

  if ticks >= 365 [ stop ]

  ask links [ set thickness 0 ]

  ask vehicles [
    let worklocation wlocation
    ask [link-with worklocation] of homelocation [
      set thickness 0.3
      set dist link-length
      ]
    face worklocation  ;; not strictly necessary, but improves the visuals a bit
    move-to worklocation

    ; Gasoline price is about $3.37/gal, mileage of a car is 20 mpg on avg
    ; so $/mile is 3.37 * 0.0532  = 0.179
    set convdisutil convdisutil + ( 0.179 * dist )

    ; Electricity pricing is $0.0841 / kwh, eff of BEV is 0.239 kWh/mile
    ; $/mile is 0.0841 * 0.239 = 0.02
    set bevdisutil bevdisutil + ( 0.02 * dist )

    ; Hydrogen price is $4.38 / gge, eff is 0.027 gpm
    ; $/mile is 4.38 * 0.027 = 0.12
    set fcvdisutil fcvdisutil + ( 0.12 * dist )

    set range range - dist
    set fcvrange fcvrange - dist
    if any? patches with [wcharge? = 1] [ set range range + 24]
    if any? patches with [pcolor = 67 ] in-radius 5 [ set fcvrange fcvrange + 250]

  ]

  ask vehicles [

    let new-location one-of [link-neighbors] of homelocation
    ask [link-with new-location] of homelocation [
      set thickness 0.3
      set dist link-length
      ]
    face new-location  ;; not strictly necessary, but improves the visuals a bit
    move-to new-location

    ; Gasoline price is about $3.37/gal, mileage of a car is 20 mpg on avg
    ; so $/mile is 3.37 * 0.0532  = 0.179
    set convdisutil convdisutil + ( 0.179 * dist )

    ; Electricity pricing is $0.0841 / kwh, eff of BEV is 0.239 kWh/mile
    ; $/mile is 0.0841 * 0.239 = 0.02
    set bevdisutil bevdisutil + ( 0.02 * dist )

    ; Hydrogen price is $4.38 / gge, eff is 0.027 gpm
    ; $/mile is 4.38 * 0.027 = 0.12
    set fcvdisutil fcvdisutil + ( 0.12 * dist )

    set range range - dist
    set fcvrange fcvrange - dist
    if any? patches with [pcharge? = 1] [ set range range + 12]
    if (count other patches with [pcolor = 67 ] in-radius 5 > 0) [ set fcvrange fcvrange + 250]
  ]


  ask vehicles [
    let new-location one-of [link-neighbors] of homelocation

    ask [link-with new-location] of homelocation [
      set thickness 0.3
      set dist link-length
      ]
    face new-location  ;; not strictly necessary, but improves the visuals a bit
    move-to new-location

    ; Gasoline price is about $3.37/gal, mileage of a car is 20 mpg on avg
    ; so $/mile is 3.37 * 0.0532  = 0.179
    set convdisutil convdisutil + ( 0.179 * dist )

    ; Electricity pricing is $0.0841 / kwh, eff of BEV is 0.239 kWh/mile
    ; $/mile is 0.0841 * 0.239 = 0.02
    set bevdisutil bevdisutil + ( 0.02 * dist )

    ; Hydrogen price is $4.38 / gge, eff is 0.027 gpm
    ; $/mile is 4.38 * 0.027 = 0.12
    set fcvdisutil fcvdisutil + ( 0.12 * dist )

    set range range - dist
    set fcvrange fcvrange - dist
    if any? patches with [wcharge? = 1] [ set range range + 12]
    if (count other patches with [pcolor = 67 ] in-radius 5 > 0) [ set fcvrange fcvrange + 250]

    if(new-location != homelocation) [
        set new-location one-of [link-neighbors] of homelocation
       face new-location  ;; not strictly necessary, but improves the visuals a bit
       move-to new-location

       ; Gasoline price is about $3.37/gal, mileage of a car is 20 mpg on avg
       ; so $/mile is 3.37 * 0.0532  = 0.179
       set convdisutil convdisutil + ( 0.179 * dist )

       ; Electricity pricing is $0.0841 / kwh, eff of BEV is 0.239 kWh/mile
       ; $/mile is 0.0841 * 0.239 = 0.02
       set bevdisutil bevdisutil + ( 0.02 * dist )

       ; Hydrogen price is $4.38 / gge, eff is 0.027 gpm
       ; $/mile is 4.38 * 0.027 = 0.12
       set fcvdisutil fcvdisutil + ( 0.12 * dist )

       set range range - dist
       set fcvrange fcvrange - dist
       if any? patches with [wcharge? = 1] [ set range range + 12]
       if (count other patches with [pcolor = 67 ] in-radius 5 > 0) [ set fcvrange fcvrange + 250]
       ]
     face homelocation
     move-to homelocation

    ; Gasoline price is about $3.37/gal, mileage of a car is 20 mpg on avg
    ; so $/mile is 3.37 * 0.0532  = 0.179
    set convdisutil convdisutil + ( 0.179 * dist )

    ; Electricity pricing is $0.0841 / kwh, eff of BEV is 0.239 kWh/mile
    ; $/mile is 0.0841 * 0.239 = 0.02
    set bevdisutil bevdisutil + ( 0.02 * dist )

    ; Hydrogen price is $4.38 / gge, eff is 0.027 gpm
    ; $/mile is 4.38 * 0.027 = 0.12
    set fcvdisutil fcvdisutil + ( 0.12 * dist )

    if any? patches with [hcharge? = 1] [ set range range + 42]
    if (count other patches with [pcolor = 67 ] in-radius 5 > 0) [ set fcvrange fcvrange + 250]

    if range < 0 [set bevdisutil bevdisutil + 25 ] ;; if range is negative, then it means BEV does not have sufficient chargers
                                                   ;; so a $25/day penalty is given (approx. price of a rental car per day)
    if range > 0 [set bevdisutil bevdisutil]

    if fcvrange < 0 [ set fcvdisutil fcvdisutil + 25 ]  ;; if range is negative, then it means FCV does not have sufficient stations to refuel
                                                        ;; so a $25/day penalty is given (approx. price of a rental car per day)
    if fcvrange > 0 [ set fcvdisutil fcvdisutil ]

    ;; Neighborhood effect: If more than 50% of the neighbors in the 5-mile radius
    ;; prefer BEVs or FCVs (based on their disutility) then there is an utility for the vehicle in question
    if neighborhood-effect [

      if ( count other vehicles in-radius 5 > 0 ) [
        if (( count other vehicles with [bevdisutil < convdisutil and bevdisutil < fcvdisutil] in-radius 5 ) /
        ( count other vehicles in-radius 5 ) > 0.5 ) [ set bevdisutil bevdisutil - 25]
      ]

      if ( count other vehicles in-radius 5 > 0 ) [
        if (( count other vehicles with [fcvdisutil < convdisutil and fcvdisutil < bevdisutil] in-radius 5 ) /
        ( count other vehicles in-radius 5 ) > 0.5 ) [ set fcvdisutil fcvdisutil - 25]
      ]

    ]


  ]

  tick


end

;; This routine allows the user to create hydrogen stations in real-time
to place-h2stations

  if mouse-down? [
    ask patch mouse-xcor mouse-ycor [ set pcolor 67 ]
    display
  ]

end

;; This routine allows the user to create public charging stations in real-time
to place-chargers

  if mouse-down? [
    ask patch mouse-xcor mouse-ycor [ set pcolor violet set pcharge? 1 ]
    display
  ]
end


;; The purchase probabilities are calculated using multinomial logistic regression approach
;; The respective probabilities are reported for each vehicle technology
to-report conventional
  report exp (- convdisutil / 1000 ) / ( exp (- convdisutil / 1000 ) + exp ( - fcvdisutil / 1000 ) + exp ( - bevdisutil / 1000 ))
end

to-report bev
  report exp (- bevdisutil / 1000 ) / ( exp (- convdisutil / 1000 ) + exp ( - fcvdisutil / 1000 ) + exp ( - bevdisutil / 1000 ))
end

to-report fcv
  report exp (- fcvdisutil / 1000 ) / ( exp (- convdisutil / 1000 ) + exp ( - fcvdisutil / 1000 ) + exp ( - bevdisutil / 1000 ))
end
@#$#@#$#@
GRAPHICS-WINDOW
508
14
988
515
16
16
14.242424242424242
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
23
15
93
48
SETUP
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
111
15
174
48
GO
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
22
74
203
107
num-population
num-population
0
100
80
1
1
NIL
HORIZONTAL

SLIDER
216
74
388
107
share-workplaces
share-workplaces
0.1
1
0.2
0.1
1
NIL
HORIZONTAL

SLIDER
20
121
202
154
homecharge-share
homecharge-share
0
1
0.5
0.1
1
NIL
HORIZONTAL

SLIDER
215
120
387
153
workcharge-share
workcharge-share
0
1
0.05
0.01
1
NIL
HORIZONTAL

BUTTON
218
208
354
241
NIL
place-h2stations
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
75
208
201
241
NIL
place-chargers
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
17
166
212
199
public-chargingstations
public-chargingstations
0
50
5
1
1
NIL
HORIZONTAL

SLIDER
217
167
389
200
h2-stations
h2-stations
0
10
1
1
1
NIL
HORIZONTAL

MONITOR
38
359
98
404
Conv.
mean [ conventional ] of vehicles
3
1
11

MONITOR
38
407
96
452
BEV
mean [ bev ] of vehicles
3
1
11

MONITOR
37
455
94
500
FCV
mean [ fcv ] of vehicles
3
1
11

PLOT
130
358
397
508
Mean Purchase Probability
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"Conventional" 1.0 0 -16777216 true "" "plot mean [ conventional ] of vehicles"
"BEV" 1.0 0 -13840069 true "" "plot mean [ bev ] of vehicles"
"FCV" 1.0 0 -2674135 true "" "plot mean [ fcv ] of vehicles"

SLIDER
17
259
202
292
income-morethan125K
income-morethan125K
0
1
0.1
0.1
1
NIL
HORIZONTAL

SLIDER
214
259
396
292
income-75to125K
income-75to125K
0
1 - income-morethan125K
0.3
0.1
1
NIL
HORIZONTAL

SLIDER
17
302
200
335
income-30to75K
income-30to75K
0
1 - (income-morethan125K + income-75to125K)
0.3
0.1
1
NIL
HORIZONTAL

SLIDER
214
302
395
335
income-lessthan30K
income-lessthan30K
0
1 - (income-morethan125K + income-75to125K + income-30to75K)
0.3
0.1
1
NIL
HORIZONTAL

BUTTON
195
16
258
49
WIPE
wipe
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SWITCH
268
18
455
51
neighborhood-effect
neighborhood-effect
1
1
-1000

@#$#@#$#@
## WHAT IS IT?

This model predicts the average annual purchase probability of the population of three different vehicle technologies: gasoline cars, battery electric vehicles, and fuel cell vehicles, based on their consumer demographic attributes, infrastructure availability and driving behavior.

The model consists of a neighborhood with houses, workplaces and public places. Each house has a vehicle. Each vehicle has a work location, and a few public locations assigned to the household. Each tick is a day. Every day, the vehicle goes from home to work; and from work, there are options on how the vehicle gets back home. They can get back directly home from work, or they can visit one/two public locations before getting back home.

Each house/workplace/public location have charging infrastructure randomly assigned based on input. The hydrogen stations are also located per input. The user can also assign these locations interactively.

For each vehicle, the model assigns the following costs for three vehicle technologies (conventional gasoline vehicle, Battery electric vehicle, and Fuel cell vehicle):

- Fuel cost (based on their travel distance every day)
- Income-related disutility costs (ratio of vehicle price/income--higher income households are less sensitive to vehicle prices)
- Range anxiety cost (if not enough recharging infrastructure is available)
- Refueling cost (for fuel cell vehicles, if not enough hydrogen stations are available)
- Neighborhood effect (if the neighbors in a 5-mile radius have higher threshold of BEVs/FCVs, then there is an utility added, i.e. negative cost)

Then, these costs are summed up for each vehicle technology for each car in the model. A simple multinomial logit approach is then used to estimate the purchase probability of the vehicle technology for that household.

Purchase probability of X = Exp ( X ) / Sum [ Exp ( X ) + Exp ( Y ) + Exp ( Z ) ]

The model then reports the mean purchase probability of these vehicle technologies in the neighborhood.

These inputs interact to provide the final purchase probability of the consumer. The link distance for example, plays an important role in increasing or decreasing the range anxiety cost and refueling cost. Neighborhood effect is also computed with time. The final outcome is the purchase probability at the end of the year.


## HOW IT WORKS

### Initialize (SETUP):

- num-population: Choose the number of population in the city. This will create a group of houses (with one car each).

- The 'share-workplaces' variable creates the workplaces in the city as a percentage share of the total population. The model also creates a certain public locations (these could be grocery stores, day care centers, etc.) as some share of population.

- homecharge-share and workcharge-share variables assigns the charger availability at home and work. For example, 0.5 value of homecharge-share assigns 50% of houses with home charging availability.

- The user can include the number of public chargers available in the city by choosing the number of public-chargingstations. This will randomly choose some public locations to have chargers.

- h2-stations variable randomly assigns certain patches to be hydrogen stations.

- place-chargers and place-h2stations are interactive buttons that allows the user to place stations or chargers at certain locations instead of letting the model choose the locations randomly.

- the income 'sliders' allows the user to choose the share of income levels in the city. The sum of all these shares add up to 1.

- the neighborhood-effect chooser allows the user the determine the purchase probability with or without the neighbor effect of vehicle purchases.

We reset the ticks.

At setup, every car is assigned a house and a workplace. Links are generated from home to the workplace, and 2 other public locations.

Based on the income distribution (and the vehicle prices--harcoded in the model), the model predetermines the 'purchase probability' of each vehicle type. These will be refined as the model runs, as it starts including other parameters in the purchase probability estimation.

### Iterative/Tick (GO):

Each tick acts as a 'day'.

Each day, the consumer drives from home to work first. Then, from work, the consumer has options.

- They can go home.
- They can visit a public location (grocery / day care) and drive home from there.
- They can visit 2 public locations and drive home from there.

The model randomly chooses these decisions for the consumers.

At each tick, the consumers drive from home to work, and visit other places (optionally) and drive back home. The model runs for 365 ticks (365 days).

The distance between these places are used for calculating the fuel cost for each type of vehicle.

The distances also determine the 'range limitation' for electric vehicles depending on their charger availability. If the consumers have chargers available at home, work and public places they visit, then they do not incur any penalty. If not, depending on the distance, they incur penalty for the electric vehicles.

Same strategy is used for hydrogen vehicles. If they have a hydrogen station in a 5-mile radius of the locations they visit, then they do not incur any penalty. Else, there is a penalty for fuel cell vehicles.

The neighborhood effect estimates the share of alternative fueled vehicles in the 5-mile radius of the consumer. If it exceeds 50%, it assigns a small utility to the consumer for the respective vehicle.

#### Model core

The model assigns penalties and preference points to each vehicle technology based on their characteristics. Then, these points are sent to a multinomial logit model to predict the purchase probabilities.


### 'WIPE' button:

WIPE button has to be used carefully. This is disabled before the first run. Once, the model finishes the first run (365 ticks), the user can click on 'WIPE' to restore the utilities, clear plots. This retains the same network.

Then the user can choose to 'place' stations or charger, or turn on/off the neighborhood effect to observe the change in purchase probabilities of these parameters in the same network.

DO NOT use the WIPE button before the model finishes its first run. If it throws any error, then it means, it was invoked wrongly (or the previous run was incomplete), so please restart the model. Do not change any other network related parameters while using this button. It will not have any effect.


## HOW TO USE IT

Use SETUP options to initialize the network. GO button runs the model and stops after 365 ticks (days). WIPE can be used optionally to see if changes in any of these parameters (neighborhood-effect, place-h2stations, or place-chargers) have any effect on the outcome.

## THINGS TO NOTICE

The model mainly predicts and plots the average purchase probability of vehicle technologies of the population in this city. See the monitor and the plot to observe how the daily variation in driving distances can influence the purchase probabilities.

## THINGS TO TRY

There are several things that can be tried with this model:

- Different population densities (num-population)

- Turn on/off the neighborhood effect (optionally after WIPE to see the effect on the same network)

- Different shares of home or work recharger availability

- Different public charger and hydrogen station availability

- Interactive public charger and hydrogen station locations (optionally after WIPE to see the effect on the same network)

- Different income distribution

## EXTENDING THE MODEL

- Include weekday/weekend distinction
- Different population having different VMT distribution rather than model choosing the links randomly

## RELATED MODELS

Uri Wilensky's one turtle per patch model was used to initialize locations, and car per household.

The Link-Walking turtles model from the library was used to imitate the links between the locations, on how cars travel between them.

## CREDITS AND REFERENCES

The 'disutility cost' related to consumer purchase behavior is taken from US Department of Energy report "Non-Cost Barriers to Consumer Adoption of New Light-Duty Vehicle Technologies": http://www.nrel.gov/docs/fy13osti/55639.pdf

## COPYRIGHT

This model is developed by Kalai Ramea (2016). For any questions, please contact kalai.ramea@gmail.com.
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

building store
false
0
Rectangle -7500403 true true 30 45 45 240
Rectangle -16777216 false false 30 45 45 165
Rectangle -7500403 true true 15 165 285 255
Rectangle -16777216 true false 120 195 180 255
Line -7500403 true 150 195 150 255
Rectangle -16777216 true false 30 180 105 240
Rectangle -16777216 true false 195 180 270 240
Line -16777216 false 0 165 300 165
Polygon -7500403 true true 0 165 45 135 60 90 240 90 255 135 300 165
Rectangle -7500403 true true 0 0 75 45
Rectangle -16777216 false false 0 0 75 45

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
NetLogo 5.3.1
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
