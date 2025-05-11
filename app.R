
# app.R

library(shiny)
library(shinydashboard)
library(plotly)
library(dygraphs)
library(leaflet)
library(leaflet.extras)
library(lubridate)
library(dplyr)
library(xts)

ui <- dashboardPage(
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
                box(width = 6, title = "Cargar archivo de Uber", status = "primary", solidHeader = TRUE,
                    fileInput("uber_file", "Archivo CSV de Uber")),
                box(width = 6, title = "Cargar archivo de Uber Eats", status = "info", solidHeader = TRUE,
                    fileInput("eats_file", "Archivo CSV de Uber Eats"))
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
    df$request_time <- as.Date(df$request_time)
    df$year_month <- floor_date(df$request_time, "month")
    df
  })
  
  orders <- reactive({
    req(input$eats_file)
    df <- read.csv(input$eats_file$datapath)
    df$request_time <- as.Date(df$Request_Time_Local)
    df$year_month <- floor_date(df$request_time, "month")
    df
  })
  
  output$uber_ui <- renderUI({
    req(trips())
    df <- trips()
    city_timeline <- df %>% count(city, year_month)
    daily_spending <- df %>% group_by(request_time) %>% summarise(total = sum(fare_amount, na.rm = TRUE))
    trip_points <- df %>% filter(!is.na(begintrip_lat), !is.na(begintrip_lng))
    df_xts <- xts(df$distance, order.by = as.Date(df$request_time))
    
    tagList(
      fluidRow(
        valueBox(length(df$request_time), "Viajes Totales", icon = icon("taxi"), color = "blue"),
        valueBox(paste0(round(sum(df$fare_amount, na.rm=TRUE), 2), " $"), "Total Gastado", icon = icon("dollar-sign"), color = "green"),
        valueBox(paste0(round(sum(df$distance, na.rm=TRUE), 1), " km"), "Distancia Total", icon = icon("road"), color = "purple")
      ),
      fluidRow(
        box(width = 6, title = "Solicitudes por Ciudad", status = "primary", solidHeader = TRUE,
            plotlyOutput("city_plot", height = "300px")),
        box(width = 6, title = "Gasto Diario en Uber", status = "info", solidHeader = TRUE,
            plotlyOutput("daily_spending_plot", height = "300px"))
      ),
      fluidRow(
        box(width = 6, title = "Mapa de Inicios de Viajes", status = "warning", solidHeader = TRUE,
            leafletOutput("map_plot", height = "300px")),
        box(width = 6, title = "Mapa de Calor", status = "danger", solidHeader = TRUE,
            leafletOutput("heat_map", height = "300px"))
      ),
      fluidRow(
        box(width = 12, title = "Distancia Recorrida (Serie Temporal)", status = "success", solidHeader = TRUE,
            dygraphOutput("distance_series", height = "300px"))
      )
    )
  })
  
  output$eats_ui <- renderUI({
    req(orders())
    df <- orders()
    orders_monthly <- df %>% count(year_month)
    eats_spending <- df %>% group_by(request_time) %>% summarise(total = sum(Order_Price, na.rm = TRUE))
    
    tagList(
      fluidRow(
        valueBox(length(df$request_time), "Pedidos Totales", icon = icon("hamburger"), color = "orange"),
        valueBox(paste0(round(sum(df$Order_Price, na.rm=TRUE), 2), " $"), "Total Gastado", icon = icon("dollar-sign"), color = "teal"),
        valueBox(paste0(round(mean(df$Order_Price, na.rm=TRUE), 2), " $"), "Gasto Promedio por Pedido", icon = icon("chart-line"), color = "olive")
      ),
      fluidRow(
        box(width = 6, title = "Pedidos por Mes", status = "primary", solidHeader = TRUE,
            plotlyOutput("orders_plot", height = "300px")),
        box(width = 6, title = "Gasto Diario", status = "info", solidHeader = TRUE,
            plotlyOutput("eats_daily_plot", height = "300px"))
      )
    )
  })
  
  # Gráficos Uber
  output$city_plot <- renderPlotly({
    df <- trips()
    city_timeline <- df %>% count(city, year_month)
    plot_ly(city_timeline, x = ~year_month, y = ~n, color = ~city, type = 'scatter', mode = 'lines+markers') %>%
      layout(title = "Solicitudes por ciudad", xaxis = list(title = "Mes"), yaxis = list(title = "Cantidad"))
  })
  
  output$daily_spending_plot <- renderPlotly({
    df <- trips()
    daily_spending <- df %>% group_by(request_time) %>% summarise(total = sum(fare_amount, na.rm = TRUE))
    plot_ly(daily_spending, x = ~request_time, y = ~total, type = 'bar', marker = list(color = 'steelblue')) %>%
      layout(title = "Gasto diario en Uber", xaxis = list(title = "Fecha"), yaxis = list(title = "Gasto ($)"))
  })
  
  output$map_plot <- renderLeaflet({
    df <- trips() %>% filter(!is.na(begintrip_lat), !is.na(begintrip_lng))
    leaflet(data = df) %>%
      addTiles() %>%
      addCircleMarkers(~begintrip_lng, ~begintrip_lat, radius = 3, color = "red", fillOpacity = 0.6)
  })
  
  output$heat_map <- renderLeaflet({
    df <- trips() %>% filter(!is.na(begintrip_lat), !is.na(begintrip_lng))
    leaflet(data = df) %>%
      addTiles() %>%
      addHeatmap(lng = ~begintrip_lng, lat = ~begintrip_lat, blur = 20, max = 0.05, radius = 15)
  })
  
  output$distance_series <- renderDygraph({
    df <- trips()
    df_xts <- xts(df$distance, order.by = as.Date(df$request_time))
    dygraph(df_xts, main = "Distancia recorrida") %>%
      dyOptions(drawPoints = TRUE, pointSize = 2, colors = "green") %>%
      dyRangeSelector()
  })
  
  # Gráficos Uber Eats
  output$orders_plot <- renderPlotly({
    df <- orders()
    orders_monthly <- df %>% count(year_month)
    plot_ly(orders_monthly, x = ~year_month, y = ~n, type = 'scatter', mode = 'lines+markers', line = list(color = 'orange')) %>%
      layout(title = "Pedidos por Mes", xaxis = list(title = "Mes"), yaxis = list(title = "Cantidad de Pedidos"))
  })
  
  output$eats_daily_plot <- renderPlotly({
    df <- orders()
    eats_spending <- df %>% group_by(request_time) %>% summarise(total = sum(Order_Price, na.rm = TRUE))
    plot_ly(eats_spending, x = ~request_time, y = ~total, type = 'bar', marker = list(color = 'darkorange')) %>%
      layout(title = "Gasto Diario en Uber Eats", xaxis = list(title = "Fecha"), yaxis = list(title = "Gasto ($)"))
  })
}

shinyApp(ui, server)
