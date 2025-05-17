
# app.R

# Proyecto final de la materia Graficos por Computadora
#   Objetivo:
#       Visualizacion de datos
#   Integrantes: 
#       Lopez Gutierrez Carlos Eduardo
#       Zapien Saavedra David      
#       Morales Teloxa David

# Librerias a utilizar
library(shiny)
library(shinydashboard)
library(shinythemes)
library(plotly)
library(dygraphs)
library(leaflet)
library(leaflet.extras)
library(lubridate)
library(dplyr)
library(xts)

ui <- dashboardPage(
  skin = "blue",
  dashboardHeader(title = "Visualización Uber & Uber Eats"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Cargar Datos", tabName = "upload", icon = icon("upload")),
      menuItem("Uber", tabName = "uber", icon = icon("car")),
      menuItem("Uber Eats", tabName = "eats", icon = icon("utensils"))
    )
  ),
  dashboardBody(
    tabItems(
      tabItem(tabName = "upload",
              fluidRow(
                box(width = 6, title = "Archivo Uber", status = "primary", solidHeader = TRUE,
                    fileInput("uber_file", "CSV de Uber")),
                box(width = 6, title = "Archivo Uber Eats", status = "info", solidHeader = TRUE,
                    fileInput("eats_file", "CSV de Uber Eats"))
              )
      ),
      tabItem(tabName = "uber", uiOutput("uber_ui")),
      tabItem(tabName = "eats", uiOutput("eats_ui"))
    )
  )
)

server <- function(input, output) {
  trips <- reactive({
    req(input$uber_file)
    df <- read.csv(input$uber_file$datapath)
    df$request_time <- as.POSIXct(df$request_time, format = "%Y-%m-%dT%H:%M:%OSZ", tz = "UTC")
    df$begin_trip_time <- as.POSIXct(df$begin_trip_time, format = "%Y-%m-%dT%H:%M:%OSZ", tz = "UTC")
    df$dropoff_time <- as.POSIXct(df$dropoff_time, format = "%Y-%m-%dT%H:%M:%OSZ", tz = "UTC")
    df$year_month <- floor_date(df$request_time, "month")
    df$hour <- hour(df$request_time)
    df$duration <- as.numeric(difftime(df$dropoff_time, df$begin_trip_time, units = "mins"))
    df
  })
  
  orders <- reactive({
    req(input$eats_file)
    df <- read.csv(input$eats_file$datapath)
    df$request_time <- as.POSIXct(df$Request_Time_Local)
    df$year_month <- floor_date(df$request_time, "month")
    df$hour <- hour(df$request_time)
    df$total_items <- df$Item_quantity
    df
  })
  
  # UBER UI -----
  output$uber_ui <- renderUI({
    req(trips())
    tagList(
      fluidRow(
        valueBox(length(trips()$request_time), "Viajes Totales", icon = icon("taxi"), color = "blue"),
        valueBox(paste0(round(sum(trips()$fare_amount, na.rm=TRUE), 2), " $"), "Total Gastado", icon = icon("dollar-sign"), color = "green"),
        valueBox(paste0(round(sum(trips()$distance, na.rm=TRUE), 1), " km"), "Distancia Total", icon = icon("road"), color = "purple")
      ),
      tabBox(width = 12, title = "Gráficos Uber", side = "right",
             tabPanel("Ciudades por mes", plotlyOutput("city_plot")),
             tabPanel("Gasto diario", plotlyOutput("daily_spending_plot")),
             tabPanel("Duración viajes", plotlyOutput("duration_hist")),
             tabPanel("Distribución tarifas", plotlyOutput("fare_boxplot")),
             tabPanel("Mapa inicios", leafletOutput("map_plot")),
             tabPanel("Mapa de calor", leafletOutput("heat_map")),
             tabPanel("Distancia (tiempo)", dygraphOutput("distance_series")),
             tabPanel("Uso por hora", plotlyOutput("hour_usage_plot")),
             tabPanel("Gráfico 3D", plotlyOutput("scatter3d"))
      )
    )
  })
  
  # EATS UI -----
  output$eats_ui <- renderUI({
    req(orders())
    tagList(
      fluidRow(
        valueBox(length(orders()$request_time), "Pedidos Totales", icon = icon("hamburger"), color = "orange"),
        valueBox(paste0(round(sum(orders()$Order_Price, na.rm=TRUE), 2), " $"), "Total Gastado", icon = icon("dollar-sign"), color = "teal"),
        valueBox(paste0(round(mean(orders()$Order_Price, na.rm=TRUE), 2), " $"), "Promedio Pedido", icon = icon("chart-line"), color = "olive")
      ),
      tabBox(width = 12, title = "Gráficos Uber Eats", side = "right",
             tabPanel("Pedidos por mes", plotlyOutput("orders_plot")),
             tabPanel("Gasto diario", plotlyOutput("eats_daily_plot")),
             tabPanel("Top Restaurantes", plotlyOutput("top_restaurants")),
             tabPanel("Precios por artículo", plotlyOutput("item_price_hist")),
             tabPanel("Precio vs. Cantidad", plotlyOutput("scatter_items"))
      )
    )
  })
  
  # Uber Outputs -----
  output$city_plot <- renderPlotly({
    trips() %>%
      count(city, year_month) %>%
      plot_ly(x = ~year_month, y = ~n, color = ~city, type = "scatter", mode = "lines+markers") %>%
      layout(title = "Viajes por ciudad")
  })
  
  output$daily_spending_plot <- renderPlotly({
    trips() %>%
      group_by(request_time) %>%
      summarise(total = sum(fare_amount, na.rm = TRUE)) %>%
      plot_ly(x = ~request_time, y = ~total, type = "bar") %>%
      layout(title = "Gasto diario en Uber")
  })
  
  output$duration_hist <- renderPlotly({
    plot_ly(trips(), x = ~duration, type = "histogram") %>%
      layout(title = "Duración de Viajes (min)")
  })
  
  output$fare_boxplot <- renderPlotly({
    plot_ly(trips(), y = ~fare_amount, color = ~city, type = "box") %>%
      layout(title = "Distribución de Tarifas por Ciudad")
  })
  
  output$hour_usage_plot <- renderPlotly({
    trips() %>%
      count(hour) %>%
      plot_ly(x = ~hour, y = ~n, type = "bar") %>%
      layout(title = "Frecuencia de viajes por hora del día")
  })
  
  output$map_plot <- renderLeaflet({
    leaflet(data = trips()) %>%
      addTiles() %>%
      addCircleMarkers(~begintrip_lng, ~begintrip_lat, radius = 3, color = "red")
  })
  
  output$heat_map <- renderLeaflet({
    leaflet(data = trips()) %>%
      addTiles() %>%
      addHeatmap(lng = ~begintrip_lng, lat = ~begintrip_lat, radius = 15)
  })
  
  output$distance_series <- renderDygraph({
    df_xts <- xts(trips()$distance, order.by = as.Date(trips()$request_time))
    dygraph(df_xts, main = "Distancia Recorrida")
  })
  
  output$scatter3d <- renderPlotly({
    plot_ly(trips(), x = ~begintrip_lng, y = ~begintrip_lat, z = ~fare_amount, type = "scatter3d", mode = "markers",
            marker = list(size = 2)) %>%
      layout(title = "Viajes en 3D: Long, Lat, Tarifa")
  })
  
  # Eats Outputs -----
  output$orders_plot <- renderPlotly({
    orders() %>%
      count(year_month) %>%
      plot_ly(x = ~year_month, y = ~n, type = "scatter", mode = "lines+markers") %>%
      layout(title = "Pedidos por mes")
  })
  
  output$eats_daily_plot <- renderPlotly({
    orders() %>%
      group_by(request_time) %>%
      summarise(total = sum(Order_Price, na.rm = TRUE)) %>%
      plot_ly(x = ~request_time, y = ~total, type = "bar") %>%
      layout(title = "Gasto diario Uber Eats")
  })
  
  output$top_restaurants <- renderPlotly({
    orders() %>%
      count(Restaurant_Name, sort = TRUE) %>%
      top_n(10, n) %>%
      plot_ly(x = ~reorder(Restaurant_Name, n), y = ~n, type = "bar") %>%
      layout(title = "Top Restaurantes", xaxis = list(title = ""), yaxis = list(title = "Pedidos"))
  })
  
  output$item_price_hist <- renderPlotly({
    plot_ly(orders(), x = ~Item_Price, type = "histogram", nbinsx = 30) %>%
      layout(title = "Distribución de precios de artículos")
  })
  
  output$scatter_items <- renderPlotly({
    plot_ly(orders(), x = ~total_items, y = ~Order_Price, type = "scatter", mode = "markers") %>%
      layout(title = "Relación Precio Total vs Cantidad de Ítems")
  })
}

shinyApp(ui, server)
