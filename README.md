# Pre-processed transport network data for Tampere

When testing routing and analysis tools for transport networks, I often find myself taking quite some time preparing small but useful example data. This includes clipping and filtering large OpenStreetMap extracts and GTFS feeds. 

To safe myself time, I use this repository to store this pre-processed data, such that I can skip this step next time. I chose the city of Tampere in Finland as study area. I find it very suitable since it is a small, modern city in which the OpenStreetMap data is of high quality and a clean GTFS feed containing all transit services in the city is openly available and regularly updated.

As bounds for the area of interest I use the following bounding box (with coordinates in CRS [EPSG:4326](https://epsg.io/4326)):

```
23.556649, 61.44593, 23.892189, 61.557975
```

## OpenStreetMap data

### Source

OpenStreetMap source data where downloaded from Geofabrik in `osm.pbf` format. This contains all OpenStreetMap data for the whole country of Finland. [Link to source](https://download.geofabrik.de/europe/finland.html).

### Pre-processing steps

The OpenStreetMap extract was **clipped** to contain only data inside the area of interest. For [ways](https://wiki.openstreetmap.org/wiki/Way), this keeps all features that interesect with the area (i.e. it does not cut existing ways at the border of the area).

The OpenStreetMap extract was **filtered** to contain only street network features plus some important opportunities that may be used when testing analysis tools related to accessibility. More specifically, the filtering steps keeps only those features that fullfill at least one of the following requirements:

- The feature is tagged with the key [highway](https://wiki.openstreetmap.org/wiki/Key:highway) and any value.
- The feature is tagged with the key [amenity](https://wiki.openstreetmap.org/wiki/Key:amenity) and value doctors, dentist, hospital, pharmacy, school or kindergarten.
- The feature is tagged with the key [shop](https://wiki.openstreetmap.org/wiki/Key:shop) and value supermarket.

Clipping and filtering was done with the command-line tools [osmconvert](https://wiki.openstreetmap.org/wiki/Osmconvert) and [osmfilter](https://wiki.openstreetmap.org/wiki/Osmfilter). Both are part of the larger [osmctools](https://github.com/ramunasd/osmctools) package. See [this](scripts/osm.sh) bash script for the code used (executed on Ubuntu 20.04, adapt if necessary for other operating systems).

## GTFS data

### Source

The GTFS feed for Tampere was downloaded from OpenMobilityData in `zip` format. This contains the local transit schedule as well as longer distance trips to other cities in Finland. [Link to source](https://transitfeeds.com/p/tampereen-joukkoliikenne/727).

### Pre-processing steps

The stops table of the GTFS feed was **filtered spatially** to contain only those stop locations inside the area of interest, and **filtered temporally** to contain only those stops that have trips departing between 6:00 AM and 12:00 PM. All other tables where **filtered** accordingly, such that only those rows having a relation to the filtered stops where kept. For example, only those stop time entries at the filtered stops where preserved, only those trips that visit any of the filtered stops where preserved, et cetera.

Clipping and filtering was done in R using the R packages [sf](https://github.com/r-spatial/sf/), [gtfsio](https://github.com/r-transit/gtfsio) and [data.table](https://github.com/Rdatatable/data.table). See [this](scripts/gtfs.R) R script for the code used.


