library(readr)
library(tidyverse)

df1 <- read.csv("data/taxparcels2024.csv")
# df2 <- read.csv("path/to/df2.csv")
df2 <- read.csv("C:/Users/rccli/Documents/gis/yellowmedicine/data/taxparcels2024.csv")

# Compare column names
all(names(df1) == names(df2))

# Compare the structure of the dataframes (columns, types)
str(df1)
str(df2)


library(daff)
diff <- diff_data(df1, df2)
render_diff(diff) # Prints differences in a clear format


##%######################################################%##
##%######################################################%##
##%######################################################%##
#                                                          #
####       CREATE TRS and TS variables (twprng)         ####
#                                                          #
##%######################################################%##

# Create the 'TRS' variable
taxparcels2024 <- taxparcels2024 %>%
  mutate(TRS = paste(township, range, section, sep = "-"))

# Create the 'TR' variable
taxparcels2024 <- taxparcels2024 %>%
  mutate(TR = paste(township, range, sep = "-"))

# Move 'TRS' and 'TR' to follow 'capacity' and then remove 't_r_s'
taxparcels2024 <- taxparcels2024 %>%
  relocate(TRS, TR, .after = capacity) %>%
  select(-t_r_s)

write_csv(taxparcels2024, "data/taxparcels2024.csv")
