# Load or install required packages
if(!require(shiny)){install.packages("shiny")}
if(!require(shinyjs)){install.packages("shinyjs")}
if(!require(dplyr)){install.packages("dplyr")}
if(!require(sf)){install.packages("sf")}
if(!require(ggplot2)){install.packages("ggplot2")}
if(!require(shinyWidgets)){install.packages("shinyWidgets")}
if(!require(lubridate)){install.packages("lubridate")}
if(!require(brazilmaps)){install.packages("brazilmaps")}
# library(ggrepel)


# Constants
# Brazilian States (Save app.R with Encoding UTF-8)
STATES <- c('ACRE', 'ALAGOAS', "AMAPÁ", 'AMAZONAS', 'BAHIA', 'CEARÁ', 'DISTRITO FEDERAL', 'ESPÍRITO SANTO', 'GOIÁS', 'MARANHÃO', 'MATO GROSSO', 'MATO GROSSO DO SUL', 'MINAS GERAIS', 'PARÁ', 'PARAÍBA', 'PARANÁ', 'PERNAMBUCO', 'PIAUÍ', 'RIO DE JANEIRO', 'RIO GRANDE DO NORTE', 'RIO GRANDE DO SUL', 'RONDÔNIA', 'RORAIMA', 'SANTA CATARINA', 'SÃO PAULO', 'SERGIPE', 'TOCANTINS')

# Graphs
GRAPH_GENERAL_TYPE <- c('Comparison', 'Composition', 'Distribution', 'Map')
COMPARISON_OPTS <-  c('Bar Graph - Compare States', 'Bar Graph - Compare States Over Time', 'Boxplot - Compare States', 'Grouped Bar Graph', 'Line Graph', 'Scatterplot - Jitter') # coord_flip()
COMPOSITION_OPTS <-  c('Pie Chart', 'Treemap') # 'Stacked Bar Graph', 
DISTRIBUTION_OPTS <-  c('Histogram - Combine States', 'Histogram - Distinct States')
MAP_OPTS <- c('Choropleth Map')
# Graph type vectors
GRAPH_BY_STATE <- c('Bar Graph - Compare States', 'Boxplot - Compare States')

# Time
SELECT_STATES <- "States: "
SELECT_YEAR <- "Years: "
SELECT_MONTH <- "Months: "
TIME_SELECTIONS <- c('Select date range', 'View year totals', 'View month totals')

BR_df <- read.csv('data/amazon_with_date.csv', encoding="UTF-8")
BR_df$state <- as.factor(BR_df$state)
BR_df$date <- as.Date(BR_df$date)
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
          # Looks ugly for comparison graphs with too many states
          # `maxOptions` = ?
          `actions-box` = TRUE, 
          size = 8,
          `selected-text-format` = "count > 3"
        ), 
        multiple = TRUE,
        selected = c('AMAZONAS','PARANÁ', 'RIO DE JANEIRO', 'SÃO PAULO')
      ),
      hr(),
      strong(id = 'time_setting', 'Time Settings:'),
      # materialSwitch(inputId = "time_switch", label = "", status = "primary"),
      selectizeInput(inputId = 'time_selection', 
                     label = 'Select a time view:', 
                     choices = TIME_SELECTIONS,
                     selected = TIME_SELECTIONS[1]),
      uiOutput("time_filter"),
      actionButton(inputId = "submit_graph",label = "Submit Graph"),
    ),
    mainPanel(
      div(id = 'plot_div',
          style = "min-height: 300px;",
          plotOutput('plot')
          )
    )
  )
)


server <- function(input, output, session) {
  
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
  output$time_filter <- renderUI({
    if(input$time_selection == TIME_SELECTIONS[1]){
      tagList(
        splitLayout(
          dateInput(inputId = 'beg_date', 
                    label = 'From:',
                    value = '1998-01-01',
                    startview = "month"),
          dateInput(inputId = 'end_date', 
                    label = "To:", 
                    value = '2017-12-31', 
                    startview = "month")
        )
      )
    }
    else if(input$time_selection == TIME_SELECTIONS[2]){
      pickerInput(inputId = "selected_years",
                  label = SELECT_YEAR,
                  choices = c(1998:2017),
                  options = list(
                    `actions-box` = TRUE,
                    `selected-text-format` = "count > 3",
                    size = 8
                  ),
                  multiple = TRUE,
                  selected = c(1998:2017))
    }
    else if(input$time_selection == TIME_SELECTIONS[3]){
      pickerInput(inputId = "selected_months",
                  label = SELECT_MONTH,
                  choices = month.name,
                  options = list(
                    `actions-box` = TRUE, 
                    `selected-text-format` = "count > 3",
                    size = 8
                  ),
                  multiple = TRUE,
                  selected = month.name)
    }
  })
  
  observeEvent(input$specific_plot_type,{
    if(input$specific_plot_type %in% GRAPH_BY_STATE){
      updateSelectizeInput(session,
                           "time_selection",
                           choices = c(TIME_SELECTIONS[1]),
                           selected = TIME_SELECTIONS[1]
    )}
    else{
      updateSelectizeInput(session,
                           "time_selection",
                           choices = TIME_SELECTIONS,
                           selected = TIME_SELECTIONS[1]
      )}
    }
  )

  observeEvent(
    input$submit_graph,
    {
      p_type <- input$specific_plot_type
      # x-axis is time
      if(p_type %in% c('Line Graph', 'Scatterplot - Jitter', 'Bar Graph - Compare States Over Time')){
        # default (year) is False
        time_measure <- input$time_selection
        if(time_measure == TIME_SELECTIONS[1]){
          df <- BR_df %>%
            dplyr::filter(., state %in% input$selected_states) %>%
            dplyr::filter(between(as.Date(date), input$beg_date, input$end_date))
        }
        else if(time_measure == TIME_SELECTIONS[2]){
          df <- BR_df %>%
            dplyr::filter(state %in% input$selected_states) %>%
            dplyr::filter(year(date) %in% input$selected_years)
          if(p_type == 'Line Graph'){
            df <- aggregate(fires ~ year + state, data = df, sum)
          }
        }
        else if(time_measure == TIME_SELECTIONS[3]){
          df <- BR_df %>%
            dplyr::filter(state %in% input$selected_states) %>%
            dplyr::filter(month(date, label = T, abbr = F) %in% input$selected_months)
          if(p_type == 'Line Graph'){
            df <- aggregate(fires ~ month + state, data = df, sum)
          }
        }
        else{
          throw("Invalid time setting: ", time_measure)
        }
        gg <- ggplot(df) +
          theme(legend.position="bottom") +
          labs (x = paste0("Time (",
                           time_col(time_measure),
                           ")"),
                y = "Number of Fires", 
                title = "Number of Fires Over Time",
                colour = "State"
                )
        # conditional graph type additions
        if(p_type == 'Line Graph'){
          gg <- gg + geom_line(aes_string(
            x = time_col(time_measure),
            y = 'fires',
            color = 'state'))
        }
        else if(p_type == 'Scatterplot - Jitter'){
          gg <- gg + geom_jitter(aes_string(
            x = time_col(time_measure),
            y = 'fires',
            color = 'state'))
        }
        else if(p_type == 'Bar Graph - Compare States Over Time'){
          gg <- gg + 
            geom_bar(position="dodge", 
                     stat="identity", 
                     aes_string(
                       x = time_col(time_measure),
                       y = 'fires',
                       color = 'state'))
        }
        output$plot <- renderPlot({
          options(scipen = 6)
          gg
        })
      }
      
      # x-axis is states
      else if(p_type %in% GRAPH_BY_STATE){
        df <- BR_df %>%
          dplyr::filter(state %in% input$selected_states) %>%
          dplyr::filter(between(as.Date(date), input$beg_date, input$end_date))
        if(p_type == GRAPH_BY_STATE[1]){
          df <- aggregate(fires ~ state, data = df, sum)
        }
        gg <- ggplot(df) +
          theme(legend.position="bottom") +
          labs (x = "Brazilian States",
                y = "Number of Fires", 
                title = paste0("Number of Fires From ",
                               input$beg_date,
                               " to ",
                               input$end_date, 
                               collapse = ' '),
                colour = "State") 
        # conditional graph type additions
        if(p_type == GRAPH_BY_STATE[1]){
          gg <- gg + 
            geom_bar(stat = "identity", 
                     aes_string(
                       x = 'state',
                       y = 'fires',
                       fill = 'state')) +
            coord_flip()
        }
        else if(p_type == GRAPH_BY_STATE[2]){
          gg <- gg + 
            geom_boxplot(outlier.colour="black", 
                         outlier.shape=19,
                         aes_string(
                           x = 'state',
                           y = 'fires',
                           color = 'state')) +
            theme(axis.text.x = element_text(angle = 90))
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


time_col <- function(time_measure){
  if(time_measure == TIME_SELECTIONS[1]){
    return("date")
  }
  else if(time_measure == TIME_SELECTIONS[2]){
    return('year')
  }
  else{
    return('month')
  }
}


shinyApp(ui = ui, server = server)