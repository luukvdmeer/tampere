#!/bin/bash

# Install dependencies
# apt install -y --no-install-recommends wget osmctools

# Get source data.
wget https://download.geofabrik.de/europe/finland-latest.osm.pbf

# Clip to bounding box.
osmconvert finland-latest.osm.pbf \
  --complete-ways \
  -b=23.556649,61.44593,23.892189,61.557975 \
  -o=tampere.o5m

# Filter features.
osmfilter tampere.o5m \
  --drop-version \
  --keep="highway= amenity=doctors =dentist =hospital =pharmacy =school =kindergarten shop=supermarket" \
  -o=tampere_filtered.o5m

# Convert back to PBF format.
osmconvert tampere_filtered.o5m -o=tampere.osm.pbf

# Clean up.
rm finland-latest.osm.pbf tampere.o5m tampere_filtered.o5m
