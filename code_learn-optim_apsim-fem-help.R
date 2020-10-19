# goal: get help from FEM getting path to coldTT parameter
#
# created: 10/10/20
#
# notes: 
#
# updated: 


rm(list = ls())


#library(remotes)
#remotes::install_github("femiguez/apsimx")
library(apsimx)
library(dplyr)
library(xml2)

# find the paths to params ------------------------------------------------

## Want to do coldTT as a trial. It's a single value, so should be easier than the other strings

#--find path to parm I want to optimize

# simulation
a_xml <- read_xml("ames-optim.apsim")

# path to it
a_xml %>%
    xml_find_all(., ".//manager2") %>%
    xml_find_all(., paste0(".//", "coldTT")) %>% 
  xml_path()
  
#--not sure if inspect_apsim will work for me. Hmm. Maybe just using the path from above will be ok. 
inspect_apsim("ames-optim.apsim", src.dir = ".",
              node = "Other",
              parm = "coldTT")

inspect_apsim("ames-optim.apsim", src.dir = ".",
              node = "Other",
              parm = "manager2")

#--example for finding paths
## Finding RUE
inspect_apsimx_replacement("Wheat-opt-ex.apsimx", src.dir = extd.dir,
                           node = "Wheat", 
                           node.child = "Leaf",
                           node.subchild = "Photosynthesis",
                           node.subsubchild = "RUE", 
                           parm = "FixedValue",
                           verbose = FALSE)
## Constructing the paths is straight-forward
pp1 <- "Wheat.Leaf.Photosynthesis.RUE.FixedValue"
pp2 <- "Wheat.Cultivars.USA.Yecora.BasePhyllochron"

## Hmm I think I need to have it in his syntax. 
# Doubt this will work but try. 

pp3 <- "folder.simulation.area.manager2[5].ui.coldTT"


# optimization ------------------------------------------------------------

## wop is for wheat optimization
# wop <- optim_apsimx("Wheat-opt-ex.apsimx", 
#                     src.dir = extd.dir, 
#                     parm.paths = c(pp1, pp2),
#                     data = obsWheat, 
#                     weights = "mean",
#                     replacement = c(TRUE, TRUE),
#                     initial.values = c(1.2, 120))

## aop is for ames optimization. Nope. Need better param paths. 
aop <- optim_apsim(
  file = "ames-optim.apsim", 
  src.dir = ".",
  parm.paths = c(pp3),
  data = obs_ames, 
  weights = "mean",
  replacement = c(TRUE),
  initial.values = c(4))
