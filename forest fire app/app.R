library(shiny)
library(dplyr)
library(ggplot2)
library(ggrepel)
library(ggmap)
library(tidyverse)

# Enable Google Maps API

# Constants
PLOT_TYPES <- c('Bar', 'Cloropleth', 'Line', 'Scatter')
names(PLOT_TYPES) <- c('bar', 'cloropleth', 'line', 'scatter')

brazil_data <- read.csv('../amazon.csv')


ui <- fluidPage(
  titlePanel("Brazil Forest Fires"),

  sidebarLayout(
    sidebarPanel(
      
      radioButtons('plot_choice', 'Select a graph type:', choices = PLOT_TYPES, selected = 'bar')
    ),

    mainPanel(
      plotOutput('plot')
    )
  )
)


server <- function(input, output) {
  
}


shinyApp(ui = ui, server = server)