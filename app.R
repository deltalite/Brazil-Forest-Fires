library(shiny)
library(dplyr)
library(sf)
library(ggplot2)
library(shinyWidgets)
# library(ggrepel)
library(brazilmaps)
# library(tidyverse)


# Constants
GRAPH_GENERAL_TYPE <- c('Comparison', 'Composition', 'Map', 'Distribution')
COMPARISON_OPTS <-  c('Bar Graph', 'Boxplot', 'Line Graph', 'Scatterplot - Jitter')
COMPOSITION_OPTS <-  c('Bar Graph', 'Pie Chart', 'Treemap') # coord_flip()
DISTRIBUTION_OPTS <-  c('Histogram')
MAP_OPTS <- c('Choropleth Map')
MONTHS <- c("January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December")
SELECT_YEAR <- "Select a year: "

BR_fire_data <- read.csv('data/amazon.csv', encoding="UTF-8")
BR_fire_data$state <- as.factor(BR_fire_data$state)
map_states <- get_brmap(geo = "State", class = "sf")
plot_brmap(map_states,
           data_to_join = BR_fire_data,
           join_by = c('nome'='state'),
           var = 'Number.of.Fires')

ui <- fluidPage(
  titlePanel("Brazil Forest Fires"),

  sidebarLayout(
    sidebarPanel(
      
      selectizeInput(inputId = 'general_plot_type',
                     label = 'Select a general graph type:', 
                     choices = GRAPH_GENERAL_TYPE, selected = 'bar'),
      uiOutput("specific_plot_type"),
      # Turn to dropdown checkbox
      selectizeInput(inputId = "select_year",
                     label = SELECT_YEAR, 
                     choices = 1998:2017, 
                     selected = 2017),
    ),
    mainPanel(
      div(id = 'plot_div',
        plotOutput('plot')
        
      )
    )
  )
)


server <- function(input, output) {
  
}

# plot_brmap(map_states,
#            data_to_join = BR_fire_data,
#            join_by = c('nome'='state'),
#            var = 'Forest Fires 2018')

# map_states <- get_brmap(geo = "State", class = "sf")
# plot_brmap(map_states)


shinyApp(ui = ui, server = server)