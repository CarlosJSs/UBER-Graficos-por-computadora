# Visualización de Datos - Uber & Uber Eats

Este proyecto es una aplicación interactiva desarrollada en **R** utilizando **Shiny**. Permite visualizar datos de viajes de Uber y pedidos de Uber Eats mediante gráficos, mapas y paneles dinámicos.

## 📦 Contenido del Proyecto

- `app.R`: Código principal de la aplicación Shiny.
- `uber_analysis.R`: Script auxiliar para análisis y carga de datos de prueba.
- **Archivos de datos (requeridos):**
  - `trips_data-XXXX.csv`: Datos de viajes de Uber.
  - `user_orders-XXXX.csv`: Datos de pedidos de Uber Eats.

> **Importante:** Asegúrate de tener los archivos `.csv` mencionados si deseas hacer pruebas con el script `uber_analysis.R`. Para la app `app.R`, puedes cargar cualquier archivo CSV con el formato adecuado desde la interfaz.

---

## ⚙️ Requisitos del Sistema

### 1. Instalar R

Descarga e instala **R** desde:  
👉 https://cran.r-project.org/

### 2. Instalar RStudio (opcional pero recomendado)

Descarga e instala **RStudio** desde:  
👉 https://www.rstudio.com/products/rstudio/download/

### 3. Instalar Paquetes Necesarios

Los siguientes paquetes deben estar instalados:

```r
install.packages(c(
  "shiny", "shinydashboard", "shinythemes",
  "plotly", "dygraphs", "leaflet", "leaflet.extras",
  "lubridate", "dplyr", "xts", "ggplot2"
))
```

Alternativamente, puedes ejecutar el script `uber_analysis.R`, que se encarga de instalar los paquetes automáticamente.

---

## ▶️ Ejecución de la Aplicación

### Desde RStudio

1. Abre `app.R` en RStudio.
2. Haz clic en **Run App** en la esquina superior derecha del script.

### Desde R directamente

1. Abre una terminal R.
2. Ejecuta:

```r
shiny::runApp("ruta/del/proyecto")
```

---

## 📁 Archivos CSV requeridos

Para que la aplicación funcione correctamente, necesitas subir archivos `.csv` mediante la interfaz cuando ejecutas la app:

### Para Uber:
- Debe contener al menos las siguientes columnas:
  - `request_time`, `begin_trip_time`, `dropoff_time`
  - `fare_amount`, `distance`, `begintrip_lat`, `begintrip_lng`, `city`

### Para Uber Eats:
- Debe contener al menos:
  - `Request_Time_Local`, `Order_Price`, `Item_quantity`, `Restaurant_Name`

Ejemplos de archivos funcionales se incluyen como:
- Para UBER:
  - `trips_data-carlos.csv`
  - `trips_data-chuy.csv`
  - `trips_data-teloxa.csv`
  - `trips_data-zapien.csv`

- Para UBER Eats:
  - `user_orders-carlos.csv`
  - `user_orders-teloxa.csv`
  - `user_orders-zapien.csv`

---

## 📊 Funcionalidades Principales

- **Panel de Uber:**
  - Viajes por ciudad y mes
  - Gasto diario
  - Duración y distribución de viajes
  - Mapas interactivos de trayectos
  - Gráfico 3D de ubicación y tarifas

- **Panel de Uber Eats:**
  - Pedidos por mes y gasto diario
  - Top restaurantes
  - Distribución de precios y relación ítems/precio

---

## 👥 Autores

- Carlos Eduardo López Gutiérrez
- David Zapién Saavedra
- David Morales Teloxa

Proyecto final para la materia **Gráficos por Computadora**.

---
