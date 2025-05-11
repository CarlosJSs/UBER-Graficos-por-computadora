
# uber_analysis.R

# Instala si es necesario
packages <- c("dplyr", "ggplot2", "plotly", "lubridate", "leaflet", "leaflet.extras", "dygraphs", "xts", "shinydashboard")
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
trips <- read.csv("trips_data-teloxa.csv", stringsAsFactors = FALSE)
orders <- read.csv("user_orders-teloxa.csv", stringsAsFactors = FALSE)

# Parsear fechas
trips$request_time <- as.Date(trips$request_time)
trips$year_month <- floor_date(trips$request_time, "month")

orders$request_time <- as.Date(orders$Request_Time_Local)
orders$year_month <- floor_date(orders$request_time, "month")

# Crear objetos globales para visualizaciones
# Uber timeline por ciudad
city_timeline <- trips %>% count(city, year_month)

# Gasto diario Uber
daily_spending <- trips %>% group_by(request_time) %>% summarise(total = sum(fare_amount, na.rm = TRUE))

# Mapa de puntos Uber
trip_points <- trips %>% filter(!is.na(begintrip_lat), !is.na(begintrip_lng))

# Serie de distancia Uber
trips_xts <- xts(trips$distance, order.by = as.Date(trips$request_time))

# Uber Eats: pedidos por mes
orders_monthly <- orders %>% count(year_month)

# Uber Eats: gasto por fecha
eats_spending <- orders %>% group_by(request_time) %>% summarise(total = sum(Order_Price, na.rm = TRUE))

# Uber Eats: gasto por categoría
# eats_by_category <- orders %>% group_by(category) %>% summarise(total = sum(Order_Price, na.rm = TRUE))
