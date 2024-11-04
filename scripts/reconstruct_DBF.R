##%######################################################%##
#                                                          #
####             RECONSTRUCT DBF FILE                   ####
#                                                          #
##%######################################################%##

library(tidyverse)
library(readr)
library(foreign)


taxparcels2024 <- read_csv("data/taxparcels2024.csv")
View(taxparcels2024)



##%######################################################%##
#                                                          #
####         Avoid Removing Attributes Globally         ####
####               Instead of removing all              ####
####      attributes, address specific problematic      ####
####          attributes or handle data types           ####
####            individually. Use Safe Data             ####
####         Type Conversions  Factors: Convert         ####
####          factors to characters carefully,          ####
####        ensuring that levels are preserved.         ####
#                                                          #
##%######################################################%##

taxparcels2024[] <- lapply(taxparcels2024, function(x) {
  if (is.factor(x)) as.character(x) else x
})


taxparcels <- taxparcels2024 |>
  rename(year = tax_year, city = taxpayer_city, state = taxpayer_state, zip = taxpayer_zip) |>
  select(-taxpayer_name, -taxpayer_address, -taxpayer_address_2, -taxpayer_address_3, -taxpayer_address_4) |>
  select(-owner_name, -owner_address_1, -owner_address_2, -owner_address_3, -owner_address_4, -city_present)

##%######################################################%##
#                                                          #
####              CSV must be a data.frame              ####
#                                                          #
##%######################################################%##

##%######################################################%##
#                                                          #
####         This is an important step.  If the         ####
####      CSV is not rewritten as a   data.frame,       ####
####         columns will not be recognized.            ####
####         Saving the csv as a dbf, will limit        ####
####         the Text Fields, such as "LEGAL"           ####
####    will limit the field size to 256 Characters     ####
####          To avoid this use PostgreSQL which        ####
####        has no limited   Row limit is 1.6GB         ####
#                                                          #
##%######################################################%##

taxparcels <- as.data.frame(taxparcels)

library(foreign)
write.dbf(taxparcels, "shape/Tax_Parcels_2/Tax_Parcels.dbf")




