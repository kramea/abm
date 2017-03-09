## Introduction

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