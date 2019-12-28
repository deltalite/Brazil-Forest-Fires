library(shiny)
library(dplyr)
library(ggplot2)
# library(ggrepel)
library(brazilmaps)
# library(tidyverse)


# Constants
PLOT_TYPES <- c('bar', 'cloropleth', 'line', 'scatter')
names(PLOT_TYPES) <- c('Bar', 'Cloropleth', 'Line', 'Scatter')
MONTHS <- c("January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December")
SELECT_YEAR <- "Select a year: "

BR_fire_data <- read.csv('../data/amazon.csv')
BR_fire_data$state <- as.factor(toupper(BR_fire_data$state))
map_states <- get_brmap(geo = "State", class = "sf")
plot_brmap(map_states,
           data_to_join = BR_fire_data,
           join_by = c('nome'='state'),
           var = 'Forest Fires 2018')

ui <- fluidPage(
  titlePanel("Brazil Forest Fires"),

  sidebarLayout(
    sidebarPanel(
      
      radioButtons('plot_choice', 'Select a graph type:', choices = PLOT_TYPES, selected = 'bar'),
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

plot_brmap(map_states,
           data_to_join = BR_fire_data,
           join_by = c('nome'='state'),
           var = 'Forest Fires 2018')

map_states <- get_brmap(geo = "State", class = "sf")
plot_brmap(map_states)


shinyApp(ui = ui, server = server)