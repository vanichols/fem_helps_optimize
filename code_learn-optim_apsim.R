# goal: learn to use optim_apsim
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
library(readr)
library(ggplot2)
library(xml2)
library(tidysawyer2)
library(lubridate)
library(saapsim)

curdir <- paste(getwd())
curdir

#--tell it the correct apsim
apsim_options(exe.path = "C:/PROGRA~2/Apsim79-r0/Model/Apsim.exe")


#--example of how to get parameter path from vignette
extd.dir <- system.file("extdata", package = "apsimx")
rue.pth <- inspect_apsim_xml("Maize75.xml", src.dir = extd.dir, parm = "rue")
ext.pth <- inspect_apsim_xml("Maize75.xml", src.dir = extd.dir, parm = "y_extinct_coef")
## To pass them to optim_apsim, combine them
pp <- c(rue.pth, ext.pth)
pp



# get default value sim results -------------------------------------------

sim0raw <- apsim("ames-optim.apsim", src.dir = ".", value = "report")

sim0 <- 
  sim0raw %>% 
  mutate(Date = ymd(Date))
  
obs_ames <- 
  read_csv("ames-obs.csv")
         
ggplot() + 
  geom_point(data = obs_ames, aes(x = Date, y = corn_buac)) + 
  geom_line(data = sim0, aes(x = Date, y = corn_buac)) + 
  ggtitle("Corn Yield")


# find the paths to params ------------------------------------------------

#--let's try doing coldTT. It's a single value, so should be easier than the other strings

#--find path to parm I want to optimize

a_xml <- read_xml("ames-optim.apsim")
a_xml %>%
    xml_find_all(., ".//manager2") %>%
    xml_find_all(., paste0(".//", "coldTT")) %>% 
  xml_path()
  
#--not sure if inspect_apsim will work for me. Hmm. Maybe just using the path from above will be ok. 
inspect_apsim("ames-optim.apsim", src.dir = ".",
              node = "Other",
              parm = "coldTT")

#--example for finding paths
## Finding RUE
inspect_apsimx_replacement("Wheat-opt-ex.apsimx", src.dir = extd.dir,
                           node = "Wheat", 
                           node.child = "Leaf",
                           node.subchild = "Photosynthesis",
                           node.subsubchild = "RUE", 
                           parm = "FixedValue",
                           verbose = FALSE)
## Finding BasePhyllochron
inspect_apsimx_replacement("Wheat-opt-ex.apsimx", src.dir = extd.dir,
                           node = "Wheat", 
                           node.child = "Cultivars",
                           node.subchild = "USA",
                           node.subsubchild = "Yecora", 
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
