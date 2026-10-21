# Analysis data dictionary

Source: Global Mangrove Watch v4.1.12, https://zenodo.org/records/21346457, CC BY 4.0.

| Field | Meaning |
| --- | --- |
| iso | Provider country/territory identifier, preserved from source |
| country | Provider country/territory name |
| year | Calendar year represented by estimate |
| extent_ha | Provider corrected mangrove extent estimate in hectares |
| lower95_ha | Provider lower 95% interval for extent, hectares |
| upper95_ha | Provider upper 95% interval for extent, hectares |
| annual_net_change_ha | Current estimate minus previous year's estimate; unavailable for first focal year |
| index_2000 | Extent divided by its own country's 2000 estimate, multiplied by 100 |
| scenario | Explicit analyst-selected rate assumption |
| annual_rate | Compound annual rate stored as a decimal, not percent |

Scenario table `extent_ha` is a conditional calculated value rather than a source observation. CSV files preserve numeric precision. Report values are rounded for reading. Net change of national totals is not gross habitat loss.
