# Tax Parcels 2024 Data Dictionary

## Overview
This dataset contains 10,738 records with 28 variables related to property tax parcels.

## Variables

### Identification Fields
| Variable Name | Data Type | Description | Example Value |
|--------------|-----------|-------------|---------------|
| objectid | numeric | Unique identifier for each record | 148151 |
| parcel_number | character | Unique parcel identification code | "02-035-3031" |
| tax_year | numeric | Assessment year | 2024 |

### Property Measurements
| Variable Name | Data Type | Description | Example Value |
|--------------|-----------|-------------|---------------|
| acres | numeric | Total acreage of parcel | 3.1 |
| deeded_acres | numeric | Acreage listed on deed | 3.1 |
| tillable_acres | numeric | Farmable acreage | 0 |

### Owner Information
| Variable Name | Data Type | Description | Example Value |
|--------------|-----------|-------------|---------------|
| fullname | character | Complete name of owner | "MEIER MARSHALL" |
| lastname | character | Last name of owner | "MEIER" |
| firstname | character | First name of owner | "MARSHALL" |
| capacity | character | Legal capacity of ownership | "RT AND" |

### Location Information
| Variable Name | Data Type | Description | Example Value |
|--------------|-----------|-------------|---------------|
| address | character | Property street address | "6226 HWY 67" |
| city | character | City name | "BELVIEW" |
| state | character | State abbreviation | "MN" |
| zip | character | Postal code | "56214" |

### Legal Description
| Variable Name | Data Type | Description | Example Value |
|--------------|-----------|-------------|---------------|
| legal | character | Legal property description | "40 FT STRIP WITH..." |
| TRS | character | Township-Range-Section identifier | "113-38-35" |
| TR | character | Township-Range identifier | "113-38" |
| township | numeric | Township number | 113 |
| range | numeric | Range number | 38 |
| section | numeric | Section number | 35 |

### Plat Information
| Variable Name | Data Type | Description | Example Value |
|--------------|-----------|-------------|---------------|
| lot | numeric | Lot number | 0 |
| block | numeric | Block number | 0 |
| plat_number | numeric | Plat identification number | 0 |
| plat_name | character | Name of the plat | NA |

### Administrative Information
| Variable Name | Data Type | Description | Example Value |
|--------------|-----------|-------------|---------------|
| city_twp_number | numeric | City/Township identification code | 2 |
| city_twp_name | character | City/Township name | "ECHO TOWNSHIP" |
| school_district_number | numeric | School district identification code | 2190 |
| school_district_name | character | School district name | "YELLOW MEDICINE EAST" |

## Notes
- NA values indicate missing or not applicable data
- ROW entries appear to be Right-of-Way parcels
- Numeric fields are stored as double precision
- Character fields may contain trailing spaces
- Some fields (lot, block, plat_number) use 0 as a default value when not applicable
