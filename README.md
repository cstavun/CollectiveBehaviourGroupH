# CollectiveBehaviourGroupH
This is the GitHub repository for the group H in collective behaviour 2023/2024


## Members: 
Clara STAVUN: [@cstavun ](https://github.com/cstavun)  
Kim GEORGET: [@kimgeorget  ](https://github.com/cstavun)  
Meggy CHAMAND: [@meggy-lie-anne](https://github.com/cstavun)  
Bella MURADIAN: [@squirreln1](https://github.com/cstavun)  

## Repository Structure:
- **FirstReport:** contains both source and a prebuilt PDF
- **SecondReport:** contains both source and a prebuilt PDF
- **FinalReport:** contains both source and a prebuilt PDF



## Introduction: 
We were looking for an article that highlighted the collective behavior of ants, in which we were interested because we found their group behavior impressive. We settled for this paper : "An agent-based model of nest-site selection in a mass-recruiting ant" by Adam L. Conin. Not only does it explain single ants behaviour, but it also studies how individual parameters lead to collective decisions, in particular during househunting, in a mass-recruting ant species. 


## Starting point:
"An agent-based model of nest-site selection in a mass-recruiting ant" - research paper by Adam Colin from October 2018 : 
https://www.sciencedirect.com/science/article/pii/S0022519318303175?casa_token=0QGBiNCPEHwAAAAA:uuc350JLVjmPiYZWk9JuRsnalEOcBd7Qo73Nmcod5xDX2yM3wn0349G9GgVh8xDD6Cx--Bq7_Q

## Final presentation:
https://www.canva.com/design/DAF4o6zkgSk/qogtGsmoZ84PkmawbWWj_w/view?utm_content=DAF4o6zkgSk&utm_campaign=designshare&utm_medium=link&utm_source=editor


## Steps of the project: 
**Phase 1: recreating the model presented in the paper.** 
The model aims to replicate the natural behavior of these ants during nest-site selection. The ants rely on pheromone trails for navigation and recruitment and use quorum thresholds for collective decisions. The agent-based model described in the paper was constructed using NetLogo, employing a stochastic and spatially explicit approach, with a specific emphasis on trail-based recruitment. 

**Phase 2:  implement a improvement on the model and the influence of different parameters on the initial model.**
In the initial model, the ants had to find a moove to a good nest. We decided to take it a step further by making them search for the best nest.
We also decided to test the influence of three parameters: the pheromone deposition, corresponding to the amount of pheromones left by the ants; the quorum, corresponding to the number of ants that need to visit a nest before it's chosen as the final nest; and the commitment base which influences the likelihood of an ant reverting to scouting after a nest selection.

**Phase 3: optimize the improvement and test the influence of different parameters on the final model.**
Finally, we improved this second model by having the ants reasses the nests continuously. We once again we tested the influence of the parameters pheromone deposition, quorum and commitment-base.



## Expected timeline:

Here is how we plan to carry out this project.

Phase 1: 23/10/2023 - 19/11/2023
During this phase, we conducted extensive research on the subject to gain a general understanding of how ant-based models work and explore existing models in this area. Simultaneously, we installed all the necessary tools for implementing the model. Additionally, we developped the initial version of our model.  
*19th November 2023 : First report* 

Phase 2: 19/11/2023 - 17/12/2023
During these weeks, we improved the model as described in phase 2. We tested our model's accuracy with various parameters.  
*17th December 2023 : Second report* 

Phase 3: 17/12/2023 - 07/01/2024
This phase included time for addressing delays from the previous phase and optimizing the model. 
Finally, we improved and tested the model, as described in phase 3.
*7th January 2024 : Last report*


## How to run the model:
To run this model, users need to have NetLogo dowloaded.
When opening the model, the user first sets the different parameters and vizualises them by clicking on the button "Setup".
To run the simulation, the user need to click on the "Go" button. The speed of the simulation can be modified but all the other parameters are set.
Once the simulation is complete, the users can see the results in the box "Success" as well as the nest chosen in the box "Chosen".


