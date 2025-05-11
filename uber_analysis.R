
# uber_analysis.R

# Instala si es necesario
packages <- c("dplyr", "ggplot2", "plotly", "lubridate", "leaflet", "leaflet.extras", "dygraphs", "xts", "shinydashboard", "shinythemes")
installed <- rownames(installed.packages())
for (p in packages) {
  if (!(p %in% installed)) install.packages(p)
}

# Cargar librerías
library(dplyr)
library(ggplot2)
library(plotly)
library(lubridate)
library(leaflet)
library(leaflet.extras)
library(dygraphs)
library(xts)

# Cargar datos
trips <- read.csv("trips_data-carlos.csv", stringsAsFactors = FALSE)
orders <- read.csv("user_orders-carlos.csv", stringsAsFactors = FALSE)

# Parsear fechas
trips$request_time <- as.POSIXct(trips$request_time)
trips$year_month <- floor_date(trips$request_time, "month")
trips$hour <- hour(trips$request_time)
trips$duration <- as.numeric(difftime(trips$dropoff_time, trips$begin_trip_time, units = "mins"))

orders$request_time <- as.POSIXct(orders$Request_Time_Local)
orders$year_month <- floor_date(orders$request_time, "month")
orders$hour <- hour(orders$request_time)
orders$total_items <- orders$Item_quantity

# Objetos de análisis
city_timeline <- trips %>% count(city, year_month)
daily_spending <- trips %>% group_by(request_time) %>% summarise(total = sum(fare_amount, na.rm = TRUE))
trip_points <- trips %>% filter(!is.na(begintrip_lat), !is.na(begintrip_lng))
trips_xts <- xts(trips$distance, order.by = as.Date(trips$request_time))

orders_monthly <- orders %>% count(year_month)
eats_spending <- orders %>% group_by(request_time) %>% summarise(total = sum(Order_Price, na.rm = TRUE))
