library(shiny)

ui <- fluidPage(
  titlePanel("Brazil Forest Fires"),

  sidebarLayout(
    sidebarPanel(
    ),

    mainPanel(
    )
  )
)


server <- function(input, output) {
}


shinyApp(ui = ui, server = server)