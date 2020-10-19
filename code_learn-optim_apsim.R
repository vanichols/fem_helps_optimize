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
library(tidyverse)
library(readxl)
library(xml2)
library(tidysawyer2)
library(lubridate)
library(saapsim)

#--getting the path of your current open file
current_path = rstudioapi::getActiveDocumentContext()$path 
setwd(dirname(current_path))
curdir <- paste(getwd())

curdir

#--tell it the correct apsim
apsim_options(exe.path = "C:/PROGRA~2/Apsim79-r0/Model/Apsim.exe")


#--example of how to get parameter path
extd.dir <- system.file("extdata", package = "apsimx")
rue.pth <- inspect_apsim_xml("Maize75.xml", src.dir = extd.dir, parm = "rue")
ext.pth <- inspect_apsim_xml("Maize75.xml", src.dir = extd.dir, parm = "y_extinct_coef")
## To pass them to optim_apsim, combine them
pp <- c(rue.pth, ext.pth)
pp


# look at data ------------------------------------------------------------
#--wheat example
data(obsWheat)
## See the structure
head(obsWheat)
## Only 10 observations
dim(obsWheat)
## Visualize the data
ggplot(obsWheat, aes(Date, Wheat.AboveGround.Wt)) + 
  geom_line() + 
  ggtitle("Biomass (g/m2)")

ggplot(obsWheat, aes(Date, Wheat.Leaf.LAI)) + 
  geom_line() +
  ggtitle("LAI")

ggplot(obsWheat, aes(Date, Wheat.Phenology.Stage)) + 
  geom_line() +
  ggtitle("Phenology Stages")

#--names have to be the same
sim0 <- read.csv(file.path(extd.dir, "wheat-sim-b4-opt.csv")) %>% as_tibble()
obsWheat %>% as_tibble()
sim0$Date <- as.Date(sim0$Date)


#--do my data
#nash_0_notill <- apsim("nash-def_0-notill.apsim", src.dir = ".", value = "report")
sim0raw <- apsim("ames-optim.apsim", src.dir = ".", value = "report")

sim0 <- 
  sim0raw %>% 
  mutate(Date = ymd(Date))
  
obs_ames <- 
  saw_tidysawyer %>% 
  filter(site == "ames", nrate_kgha == max(nrate_kgha), rotation == "cc") %>% 
  select(site, year, yield_kgha) %>% 
  mutate(Date = ymd(paste(year, "12", "31", sep = "-")),
         corn_buac = saf_kgha_to_buac_corn(yield_kgha)) %>% 
  select(-yield_kgha)
         
ggplot() + 
  geom_point(data = obs_ames, aes(x = Date, y = corn_buac)) + 
  geom_line(data = sim0, aes(x = Date, y = corn_buac)) + 
  ggtitle("Corn Yield")


# find the paths to params ------------------------------------------------
#--let's try doing coldTT. It's a single value, so should be easier?

a_xml <- read_xml("ames-optim.apsim")

#--find parm you want
a_xml %>%
    xml_find_all(., ".//manager2") %>%
    xml_find_all(., paste0(".//", "coldTT")) %>% 
  xml_path()
  
#--not sure if inspect_apsim will work for me
inspect_apsim("ames-optim.apsim", src.dir = ".",
              node = "Other",
              parm = "coldTT")


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

#--I guess build it like his example?
pp3 <- "folder.simulation.area.manager2[5].ui.coldTT"


# optimization ------------------------------------------------------------

## wop is for wheat optimization
wop <- optim_apsimx("Wheat-opt-ex.apsimx", 
                    src.dir = extd.dir, 
                    parm.paths = c(pp1, pp2),
                    data = obsWheat, 
                    weights = "mean",
                    replacement = c(TRUE, TRUE),
                    initial.values = c(1.2, 120))

## aop is for ames optimization
aop <- optim_apsim(
  file = "ames-optim.apsim", 
  src.dir = ".",
  parm.paths = c(pp3),
  data = obs_ames, 
  weights = "mean",
  replacement = c(TRUE),
  initial.values = c(4))
