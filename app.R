library(shiny)
library(shinyjs)
library(dplyr)
library(sf)
library(ggplot2)
library(shinyWidgets)
library(lubridate)
# library(ggrepel)
library(brazilmaps)
# library(tidyverse)


# Constants
# Brazilian States (Save app.R with Encoding UTF-8)
STATES <- c('ACRE', 'ALAGOAS', "AMAPÁ", 'AMAZONAS', 'BAHIA', 'CEARÁ', 'DISTRITO FEDERAL', 'ESPÍRITO SANTO', 'GOIÁS', 'MARANHÃO', 'MATO GROSSO', 'MATO GROSSO DO SUL', 'MINAS GERAIS', 'PARÁ', 'PARAÍBA', 'PARANÁ', 'PERNAMBUCO', 'PIAUÍ', 'RIO DE JANEIRO', 'RIO GRANDE DO NORTE', 'RIO GRANDE DO SUL', 'RONDÔNIA', 'RORAIMA', 'SANTA CATARINA', 'SÃO PAULO', 'SERGIPE', 'TOCANTINS')

# Graphs
GRAPH_GENERAL_TYPE <- c('Comparison', 'Composition', 'Distribution', 'Map')
COMPARISON_OPTS <-  c('Bar Graph - Compare States', 'Bar Graph - Compare Years', 'Boxplot - Compare States', 'Boxplot - Compare Years', 'Grouped Bar Graph', 'Line Graph', 'Scatterplot - Jitter') # coord_flip()
COMPOSITION_OPTS <-  c('Pie Chart', 'Treemap') # 'Stacked Bar Graph', 
DISTRIBUTION_OPTS <-  c('Histogram - Combine States', 'Histogram - Distinct States')
MAP_OPTS <- c('Choropleth Map')

# Time
SELECT_STATES <- "States: "
SELECT_YEAR <- "Years: "
SELECT_MONTH <- "Months: "
TIME_SELECTIONS <- c('Select Date Range', 'View year totals', 'View month totals')

BR_df <- read.csv('data/amazon_with_date.csv', encoding="UTF-8")
BR_df$state <- as.factor(BR_df$state)
# map_states <- get_brmap(geo = "State", class = "sf")
# plot_brmap(map_states,
#            data_to_join = BR_df,
#            join_by = c('nome'='state'),
#            var = 'Fires')

ui <- fluidPage(
  shinyjs::useShinyjs(),
  
  titlePanel("Brazil Forest Fires"),

  sidebarLayout(
    sidebarPanel(
      
      selectizeInput(inputId = 'general_plot_type',
                     label = 'Select a general graph type:', 
                     choices = GRAPH_GENERAL_TYPE, selected = 'bar'),
      uiOutput("specific_plot_type"),
      uiOutput("additional_info"),
      # Turn to dropdown checkbox
      pickerInput(
        inputId = "selected_states", 
        label = SELECT_STATES, 
        choices = STATES,
        options = list(
          `actions-box` = TRUE, 
          size = 8,
          `selected-text-format` = "count > 3"
        ), 
        multiple = TRUE,
        selected = STATES
      ),
      strong(id = 'time_setting', 'Time Setting:'),
      materialSwitch(inputId = "time_switch", label = "", status = "primary"),
      selectizeInput(inputId = 'time_selection', 
                     label = 'Select a time view:', 
                     choices = TIME_SELECTIONS,
                     selected = 'Select Date Range'),
      pickerInput(inputId = "selected_months",
                  label = SELECT_MONTH,
                  choices = month.name,
                  options = list(
                    `actions-box` = TRUE, 
                    `selected-text-format` = "count > 3",
                    size = 8
                    ),
                  multiple = TRUE,
                  selected = month.name),
      pickerInput(inputId = "selected_years",
                  label = SELECT_YEAR,
                  choices = c(1998:2017),
                  options = list(
                    `actions-box` = TRUE,
                    `selected-text-format` = "count > 3",
                    size = 8
                  ),
                  multiple = TRUE,
                  selected = c(1998:2017)),
      actionButton(inputId = "submit_graph",label = "Submit Graph"),
    ),
    mainPanel(
      div(id = 'plot_div',
        plotOutput('plot')
        
      )
    )
  )
)


server <- function(input, output) {
  
  # Reactive specific plot list
  output$specific_plot_type = renderUI({
    if(input$general_plot_type == GRAPH_GENERAL_TYPE[1]){
      opts <- COMPARISON_OPTS
    }
    else if(input$general_plot_type == GRAPH_GENERAL_TYPE[2]){
      opts <- COMPOSITION_OPTS
    }
    else if(input$general_plot_type == GRAPH_GENERAL_TYPE[3]){
      opts <- DISTRIBUTION_OPTS
    }
    else if(input$general_plot_type == GRAPH_GENERAL_TYPE[4]){
      opts <- MAP_OPTS
    }
    else{
      opts <- c()
    }
    selectizeInput(inputId = 'specific_plot_type',
                   label = 'Select a specific graph type:', 
                   choices = opts, selected = '')
  })
  
  # Month or year option available
  observeEvent(input$time_switch,{
    if(input$time_switch){
      shinyjs::hide("selected_years")
      shinyjs::show("selected_months")
      # runjs("$('#time_setting').html('Switch from years to months')")
    }
    else{
      shinyjs::show("selected_years")
      shinyjs::hide("selected_months")
      # runjs("$('#time_setting').html('Switch from months to years')")
    }
  })

  observeEvent(
    input$submit_graph,
    {
      p_type <- input$specific_plot_type
      # x-axis is time
      if(p_type %in% c('Line Graph', 'Scatterplot - Jitter')){
        # default (year) is False
        time_measure <- ifelse(input$time_switch, 'month', 'year')
        not_tm <- ifelse(input$time_switch, 'year', 'month')
        if(time_measure == 'year'){
          df <- BR_df %>%
            dplyr::filter(., state %in% input$selected_states) %>%
            dplyr::filter(year(date) %in% input$selected_years)
          if(p_type == 'Line Graph'){
            df <- aggregate(fires ~ year + state, data = df, sum) #~ year + month
          }
        }
        else{
          df <- BR_df %>%
            dplyr::filter(state %in% input$selected_states) %>%
            dplyr::filter(month(date, label = T, abbr = F) %in% input$selected_months)
          df <- aggregate(fires ~ month + state, data = df, sum)
        }
        gg <- ggplot(df) +
          # scale_x_discrete(labels=month.abb) +
          theme(legend.position="bottom") +
          labs (x = paste0("Time (",
                           ifelse(input$time_switch, "Months", "Years"),
                           ")"),
                y = "Value", 
                title = "Number of Fires Over Time",
                colour = "State"
                )
        # conditional graph type additions
        if(p_type == 'Line Graph'){
          gg <- gg + geom_line(aes_string(x = time_measure, y = 'fires', color = 'state'))
        }
        else if(p_type == 'Scatterplot - Jitter'){
          gg <- gg + geom_jitter(aes_string(x = time_measure, y = 'fires', color = 'state'))
        }
        output$plot <- renderPlot({
          options(scipen = 6)
          gg
        })
      }
    })
  # Grouped bar graph
  # ggplot(BR_df, aes(fill=states, y=fires, x=time)) + 
  #   geom_bar(position="dodge", stat="identity")
}





shinyApp(ui = ui, server = server)