# Install dependencies.
# install.packages(c("sf", "gtfsio", "data.table"))

# Load dependencies.
library(sf)
library(gtfsio)
library(data.table)

# Get source data.
url = "https://transitfeeds.com/p/tampereen-joukkoliikenne/727/latest/download"
download.file(url, "gtfs.zip")

# Load source data.
gtfs = gtfsio::import_gtfs("gtfs.zip")

# Define spatial extent.
bbox = c(23.556649, 61.44593, 23.892189, 61.557975)
names(bbox) = c("xmin", "ymin", "xmax", "ymax")
class(bbox) = "bbox"
sf::st_crs(bbox) = 4326

# Define temporal extent.
period = c("06:00", "12:00")

# Filter tables.
filter_gtfs = function(x, space = NULL, time = NULL) {
  if (is.null(space) && is.null(time)) return(x)
  # Filter stops spatially.
  # Only keep stop locations intersecting the spatial extent.
  # Only keep stop times belonging to those locations.
  if (! is.null(space)) {
    area = sf::st_as_sfc(space)
    locs = sf::st_as_sf(x$stops, coords = c("stop_lon", "stop_lat"), crs = 4326)
    x$stops = x$stops[sf::st_intersects(area, locs)[[1]], ]
    x$stop_times = subset(x$stop_times, stop_id %in% x$stops$stop_id)
  }
  # Filter stops temporally.
  # Only keep stop times departing within the temporal extent.
  # Only keep stop locations belonging to those times.
  if (! is.null(time)) {
    t0 = time[1]
    t1 = time[2]
    x$stop_times = subset(x$stop_times, departure_time >= t0 & departure_time <= t1)
    x$stops = subset(x$stops, stop_id %in% unique(x$stop_times$stop_id))
  }
  S = unique(x$stops$stop_id)
  # Filter trips.
  # Only keep trips that contain filtered stops.
  T = unique(x$stop_times$trip_id)
  x$trips = subset(x$trips, trip_id %in% T)
  # Filter routes.
  # Only keep routes that contain filtered trips.
  R = unique(x$trips$route_id)
  x$routes = subset(x$routes, route_id %in% R)
  # Filter agencies.
  # Only keep agencies that operate filtered routes.
  # Routes don't need to specify agency ids if there is only one agency.
  # In that case just keep all agencies.
  if (! is.null(x$routes$agency_id)) {
    A = unique(x$routes$agency_id)
    x$agency = subset(x$agency, agency_id %in% A)
  } else {
    A = x$agency$agency_id
  }
  # Filter services.
  # Only keep services that serve filtered trips.
  C = unique(x$trips$service_id)
  if (! is.null(x$calendar)) {
    x$calendar = subset(x$calendar, service_id %in% C)
  }
  if (! is.null(x$calendar_dates)) {
    x$calendar_dates = subset(x$calendar_dates, service_id %in% C)
  }
  # Filter frequencies.
  # Only keep frequencies belonging to filtered trips.
  if (! is.null(x$frequencies)) {
    x$frequencies = subset(x$trips, trip_id %in% T)
  }
  # Filter shapes.
  # Only keep shapes belonging to filtered trips.
  if (! is.null(x$shapes)) {
    G = unique(x$trips$shape_id)
    x$shapes = subset(x$shapes, shape_id %in% G)
  }
  # Filter transfers.
  # Only keep transfers between filtered stops.
  if (! is.null(x$transfers)) {
    x$transfers = subset(x$transfers, from_stop_id %in% S & to_stop_id %in% S)
  }
  # Filter pathways.
  # Only keep pathways between filtered stops.
  if (! is.null(x$pathways)) {
    x$pathways = subset(x$pathways, from_stop_id %in% S & to_stop_id %in% S)
  }
  # Filter levels.
  # Only keep levels that are present in filtered stops.
  if (! is.null(x$levels)) {
    L = unique(x$stops$level_id)
    x$levels = subset(x$levels, level_id %in% L)
  }
  # Filter fares.
  # If fares are linked to routes:
  # Only keep fares linked to filtered routes.
  # If fares are linked to zones:
  # Only keep fares linked to zones that contain filtered stops.
  if (! is.null(x$fare_rules)) {
    if (! is.null(x$stops$zone_id)) {
      Z = unique(x$stops$zone_id)
    } else {
      Z = c()
    }
    if (! is.null(x$fare_rules$route_id)) {
      x$fare_rules = subset(x$fare_rules, route_id %in% R)
    }
    if (! is.null(x$fare_rules$origin_id)) {
      x$fare_rules = subset(x$fare_rules, origin_id %in% Z)
    }
    if (! is.null(x$fare_rules$destination_id)) {
      x$fare_rules = subset(x$fare_rules, destination_id %in% Z)
    }
    if (! is.null(x$fare_rules$contains_id)) {
      x$fare_rules = subset(x$fare_rules, contains_id %in% Z)
    }
    F = unique(x$fare_rules$fare_id)
    x$fare_attributes = subset(x$fare_attributes, fare_id %in% F)
  }
  # Filter attributions.
  # Only keep attributions linked to filtered agencies, routes or trips.
  if (! is.null(x$attributions)) {
    if (! is.null(x$attributions$agency_id)) {
      x$attributions = subset(x$attributions, agency_id %in% A)
    }
    if (! is.null(x$attributions$route_id)) {
      x$attributions = subset(x$attributions, route_id %in% R)
    }
    if (! is.null(x$attributions$trip_id)) {
      x$attributions = subset(x$attributions, trip_id %in% T)
    }
  }
  # Filter translations.
  # Only keep translations for fields that exist in the filtered feed.
  if (! is.null(x$translations)) {
    old = x$translations
    new = list()
    new[1] = subset(old, table_name == "agency" & record_id %in% A)
    new[2] = subset(old, table_name == "stops" & record_id %in% S)
    new[3] = subset(old, table_name == "routes" & record_id %in% R)
    new[4] = subset(old, table_name == "trips" & record_id %in% T)
    new[5] = subset(old, table_name == "stop_times" & record_id %in% T)
    if (! is.null(x$pathways)) {
      I = x$pathways$pathway_id
      n = length(new) + 1
      new[n] = subset(old, table_name == "pathways" & record_id %in% I)
    }
    if (! is.null(x$levels)) {
      n = length(new) + 1
      new[n] = subset(old, table_name == "levels" & record_id %in% L)
    }
    if (! is.null(x$attributions)) {
      I = x$attributions$attribution_id
      n = length(new) + 1
      new[n] = subset(old, table_name == "attributions" & record_id %in% I)
    }
    if (! is.null(x$feed_info)) {
      n = length(new) + 1
      new[n] = subset(old, table_name == "feed_info")
    }
    x$translations = data.table::rbindlist(new)
  }
  x
}

gtfs_filtered = filter_gtfs(gtfs, space = bbox, time = period)

# Write.
export_gtfs(gtfs_filtered, "tampere.zip")

# Clean up.
file.remove("gtfs.zip")