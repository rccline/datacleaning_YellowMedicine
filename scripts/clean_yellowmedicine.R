# Load necessary libraries
library(tidyverse)
library(janitor)
library(stringr)
library(readr)
library(here)

##%######################################################%##
#                                                          #
####   NOTE:  taxparcels2024.csv, which is created in   ####
####  this script, is updated by script "add_owner.R"   ####
#                                                          #
##%######################################################%##


## Step 1: Read the original data
parcels0 <- read_csv("data/Tax_Parcels.csv") %>%
  clean_names()

# Step 2: Extract 'acres' from the 'legal' column
parcels1 <- parcels0 %>%
  mutate(acres = str_extract(legal, "^\\d+\\.\\d+"),  # Extract leading number with decimal
         acres = as.numeric(acres))  # Convert the extracted text to numeric

# Step 3: Combine taxpayer address fields and clean combined address
parcels0_clean <- parcels1 %>%
  mutate(
    combined_address = paste(taxpayer_address, taxpayer_address_2, taxpayer_address_3, taxpayer_address_4, sep = " "),
    combined_address = str_replace_all(combined_address, "\\bNA\\b", ""),  # Remove 'NA' values
    combined_address = str_squish(combined_address)  # Clean up extra whitespace
  )

# Step 4: Extract ZIP code and remove it from the combined address
parcels0_clean <- parcels0_clean %>%
  mutate(
    taxpayer_zip = str_extract(combined_address, "\\d{5}(-\\d{4})?"),  # Extract ZIP
    combined_address = str_remove(combined_address, "\\d{5}(-\\d{4})?"),  # Remove ZIP from address
    combined_address = str_squish(combined_address)  # Clean up remaining spaces
  )

# Step 5: List of valid US state codes
valid_states <- c("AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "FL", "GA", "HI", "ID", 
                  "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD", "MA", "MI", "MN", "MS", 
                  "MO", "MT", "NE", "NV", "NH", "NJ", "NM", "NY", "NC", "ND", "OH", "OK", 
                  "OR", "PA", "RI", "SC", "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV", 
                  "WI", "WY")

# Step 6: Extract state from the combined address and clean it up
parcels0_clean <- parcels0_clean %>%
  mutate(
    taxpayer_state = str_extract(combined_address, paste0("\\b(", paste(valid_states, collapse = "|"), ")\\b")),
    combined_address = str_remove(combined_address, paste0("\\b(", paste(valid_states, collapse = "|"), ")\\b")),
    combined_address = str_squish(combined_address)  # Clean up any remaining spaces
  )

# Step 7: Import the list of cities (cities_combined.csv) and clean it up
cities_combined <- read_csv(here("data/cities_combined.csv")) %>%
  mutate(
    city = str_to_upper(city),  # Convert city names to uppercase
    state = str_to_upper(state)  # Convert state codes to uppercase
  )

# Step 8: Define the function to find the city from the address and state
find_city <- function(address, state) {
  state_cities <- cities_combined %>% filter(state == !!state)
  
  # Escape special characters in city names for pattern matching
  state_cities <- state_cities %>%
    mutate(city_pattern = str_replace_all(city, "[^\\w\\s]", "\\\\$0"))
  
  # Iterate over cities to find a match in the address
  for (city in state_cities$city_pattern) {
    if (grepl(paste0("\\b", city, "\\b"), address)) {
      return(city)  # Return the first matched city
    }
  }
  return(NA_character_)  # Return NA if no match is found
}

# Step 9: Apply the function row-wise to extract cities
parcels0_clean2 <- parcels0_clean %>%
  rowwise() %>%
  mutate(
    taxpayer_city = find_city(combined_address, taxpayer_state)
  ) %>%
  ungroup()

# Step 10: Check the results
summary(parcels0_clean2$taxpayer_city)
head(parcels0_clean2 %>% select(taxpayer_city, taxpayer_state, taxpayer_zip, combined_address))

# Step 11: Summarize distinct cities by state
parcels0_clean2 %>%
  group_by(taxpayer_state) %>%
  summarise(distinct_cities = n_distinct(taxpayer_city, na.rm = TRUE)) %>%
  arrange(desc(distinct_cities))

##%######################################################%##
#           EXPORT MISMATCH FOR MANUAL REVIEW              #
####            Next Steps:    After running            ####
####                   this, you can                    ####
####     manually review the mismatched_records.csv     ####
####       file,  correct the cities, and import        ####
####       them back into your dataset if needed.       ####
#                                                          #
##%######################################################%##

# Step 1: Ensure uppercase consistency for `combined_address` and `taxpayer_city`
mismatch_parcels <- parcels0_clean2 %>%
  mutate(
    combined_address = str_to_upper(combined_address),  # Ensure combined_address is uppercase
    taxpayer_city = str_to_upper(taxpayer_city)         # Ensure taxpayer_city is uppercase
  )

# Step 2: Flag mismatched cities
mismatch_parcels <- mismatch_parcels %>%
  mutate(
    city_match_status = ifelse(is.na(taxpayer_city) | !grepl(taxpayer_city, combined_address), "Mismatch or NA", "Match")
  )

# Step 3: Filter rows where the city was not matched
mismatched_records <- mismatch_parcels %>%
  filter(city_match_status == "Mismatch or NA")

# Step 4: Export mismatched records for manual review
write_csv(mismatched_records, "data/mismatched_records.csv")

# Step 5: Check the mismatched records (first few rows for review)
head(mismatched_records %>% select(taxpayer_city, combined_address, taxpayer_state, taxpayer_zip, city_match_status))



##%######################################################%##
#                                                          #
####           Remove the matched city names            ####
####           from the combined_address  in            ####
####       parcels0_clean2  after confirming that       ####
####             the city has been matched:             ####
#                                                          #
##%######################################################%##

# Step 1: Ensure uppercase consistency for `combined_address` and `taxpayer_city`
parcels0_clean2 <- parcels0_clean2 %>%
  mutate(
    combined_address = str_to_upper(combined_address),  # Ensure combined_address is uppercase
    taxpayer_city = str_to_upper(taxpayer_city)         # Ensure taxpayer_city is uppercase
  )

# Step 2: Create a flexible pattern to remove the city
parcels0_clean3 <- parcels0_clean2 %>%
  rowwise() %>%
  mutate(
    # Debug: Print information for diagnosis
    print_info = paste0("Processing: City=", taxpayer_city, " | Address=", combined_address),
    taxpayer_city_pattern = str_replace_all(taxpayer_city, "\\s+", "\\\\s*"),  # Flexible spaces
    
    # Check if the city is present in the combined_address (case-insensitive match)
    city_present = grepl(paste0("\\b", taxpayer_city_pattern, "\\b"), combined_address, ignore.case = TRUE),
    
    # Debug: Print match status
    print_match_status = ifelse(city_present, paste0("Matched city: ", taxpayer_city), "No match"),
    
    # Remove the city from combined_address if it's found
    combined_address = ifelse(city_present,
                              str_remove(combined_address, paste0("\\b", taxpayer_city_pattern, "\\b")),
                              combined_address),
    
    # Clean up excess spaces after removing the city
    combined_address = str_squish(combined_address)
  ) %>%
  ungroup() %>%
  select(-print_info, -print_match_status, -taxpayer_city_pattern)  # Remove debugging columns

# Step 3: Check the updated combined_address after removing the city
head(parcels0_clean3 %>% select(taxpayer_city, combined_address, taxpayer_state, taxpayer_zip))

##%######################################################%##
#                                                          #
####     REGEX pattern to remove leading characters     ####
####     before 'PO Box dd' from combined_addresses     ####
#                                                          #
##%######################################################%##

# Step 1: Ensure uppercase consistency for `combined_address`
parcels0_clean3 <- parcels0_clean3 %>%
  mutate(
    combined_address = str_to_upper(combined_address)  # Ensure combined_address is uppercase
  )

# Step 2: Remove all characters before "PO Box" but retain "PO Box" and digits
parcels0_clean3 <- parcels0_clean3 %>%
  mutate(
    # Use regex to match 'PO BOX' followed by one or more digits and keep it in the result
    combined_address = ifelse(grepl("PO\\s*BOX\\s*\\d+", combined_address),
                              # Extract 'PO BOX <digits>' and remove everything before it
                              sub(".*?(PO\\s*BOX\\s*\\d+)", "\\1", combined_address),
                              combined_address),
    
    # Clean up any extra whitespace that may result from the removal
    combined_address = str_squish(combined_address)
  )

# Step 3: Check the updated combined_address after removing the preceding characters but keeping 'PO Box'
head(parcels0_clean3 %>% select(taxpayer_city, combined_address, taxpayer_state, taxpayer_zip))  


##%######################################################%##
#                                                          #
####              Clean Taxpayer Name   #               ####
####    Parse Name into firstname lastname capacity     ####
####               # concatenate with name             ####
####      data in address field where "and" exists      ####
#                                                          #
##%######################################################%##  

# Step 1: Parse the `taxpayer_name` field into `lastname`, `firstname`, and `capacity`
parcels0_clean3 <- parcels0_clean3 %>%
  mutate(
    # Split `taxpayer_name` into parts based on '/' delimiter
    name_parts = str_split(taxpayer_name, "/"),
    
    # Extract the first part as `lastname`, second as `firstname`, and third as `capacity`
    lastname = sapply(name_parts, function(x) ifelse(length(x) >= 1, x[1], NA)),
    firstname = sapply(name_parts, function(x) ifelse(length(x) >= 2, x[2], NA)),
    capacity = sapply(name_parts, function(x) ifelse(length(x) == 3, x[3], NA)),
    
    # Step 2: Concatenate `taxpayer_name` with `taxpayer_address` when the last part of `taxpayer_name` ends with "AND"
    taxpayer_name = ifelse(grepl("AND$", firstname), 
                           paste(taxpayer_name, taxpayer_address, sep = "; "), 
                           taxpayer_name)
  ) %>%
  select(-name_parts)  # Remove the temporary `name_parts` column

# Step 3: Check the results
head(parcels0_clean3 %>% select(lastname, firstname, capacity, taxpayer_name, taxpayer_address, combined_address))


##%######################################################%##
#                                                          #
####           Create 'fullname' variables              ####
####            # from taxpayer name fields             ####
#                                                          #
##%######################################################%##

# Step 1: Concatenate `lastname`, `firstname`, and `capacity` into a new variable `fullname`
parcels0_clean3 <- parcels0_clean3 %>%
  mutate(
    # Concatenate `firstname`, `lastname`, and `capacity` with a space separator
    fullname = paste(lastname, firstname, capacity, sep = " "),
    
    # Remove any extra whitespace (in case some fields like capacity are missing)
    fullname = str_squish(fullname)  # This removes unnecessary spaces
  )

# Step 2: Check the results
head(parcels0_clean3 %>% select(fullname, lastname, firstname, capacity))

##%######################################################%##
#                                                          #
####            REMOVE NAs from 'fullname'              ####
#                                                          #
##%######################################################%## 

# Step 1: Concatenate `lastname`, `firstname`, and `capacity` into a new variable `fullname`
parcels0_clean4 <- parcels0_clean3 %>%
  mutate(
    # Concatenate `lastname`, `firstname`, and `capacity` with a space separator
    fullname = paste(lastname, firstname, capacity, sep = " "),
    
    # Remove any extra whitespace (in case some fields like capacity are missing)
    fullname = str_squish(fullname),
    
    # Remove trailing "NA" from the fullname variable
    fullname = str_remove(fullname, "\\b(NA\\s*)+$")  # This will remove any trailing NA, NA NA, etc.
  )

# Step 2: Check the results
head(parcels0_clean4 %>% select(fullname, lastname, firstname, capacity))


############################################################
##%######################################################%##
#                                                          #
####       Clean owner_names and owner_addresses        ####
#                                                          #
##%######################################################%##


owner_vars <- parcels0_clean4 %>%
  select(objectid, starts_with("owner"))

ov_temp <- owner_vars %>% 
  filter(!is.na(owner_name)) 
  
write.csv(ov_temp, here::here("data/ov_temp.csv"), row.names = FALSE)

write.csv(parcels0_clean4, here::here("data/parcels4clean.csv"), row.names = FALSE)

dfcities <- parcels0_clean4 %>%
  select(taxpayer_city, taxpayer_state, taxpayer_zip) %>% 
  group_by(taxpayer_city) %>%
  summarise(distinct_cities = n_distinct(taxpayer_city, na.rm = TRUE)) %>%
  arrange(desc(distinct_cities))
  
write.csv(dfcities, here::here("data/dfcities.csv"), row.names = FALSE)


############################################################
##%######################################################%##
#                                                          #
####       Clean legal field                            ####
#                                                          #
##%######################################################%##

# Clean the 'legal' column by stripping characters up to and including "ACRES"
taxparcels2024 <- parcels0_clean4 %>%
  mutate(legal = str_remove(legal, "^.*?ACRES\\s+"))

# View the updated data to confirm
head(taxparcels2024$legal)

##%######################################################%##
##%######################################################%##
##%######################################################%##
#                                                          #
####       CREATE TRS and TS variables (twp-rng-sec)    ####
#                                                          #
##%######################################################%##


# Create the 't-r-s' variable by concatenating 'township', 'range', and 'section' with '-'
taxparcels2024 <- taxparcels2024 %>%
  mutate(TRS = paste(township, range, section, sep = "-")) |>
  mutate(TR = paste(township, range, sep = "-"))


#### REMOVE variables "taxpayer_, owner_, property_#, gis_acres, gis_sqft

taxparcels2024 <- taxparcels2024 %>%
  rename(address = combined_address, city = taxpayer_city, state = taxpayer_state, zip = taxpayer_zip) |>
  select(-starts_with("taxpayer"), -starts_with("owner"), -starts_with("property")) |>
  select(-gis_acres, -gis_sqft)
  


# REARRANGE VARIABLES

taxparcels2024 <- taxparcels2024 %>%
  select(objectid, parcel_number, tax_year, acres, fullname, lastname, firstname, capacity, address, city, state, zip, legal, TRS, TR, township, range, section, lot, block, plat_number, plat_name, deeded_acres, tillable_acres,city_twp_number, city_twp_name, school_district_name, school_district_number)
  
  
# taxparcels2024 <- taxparcels2024 %>%
#  relocate(capacity, .after = "tillable_acres") |>
#  relocate(TRS, TR, .after = capacity) 

write_csv(taxparcels2024, "data/taxparcels2024.csv")



# View the structure or a sample of the reordered dataset
head(taxparcels2024)

############################################################
##%######################################################%##
#                                                          #
####           SAVE DATASET                             ####
#             taxparcels2024.csv                           #
#                                                          #
##%######################################################%##

write.csv(taxparcels2024, here::here("data/taxparcels2024.csv"), row.names = FALSE)

