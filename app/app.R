library(shiny)

# TODO: Add fields for name
ui <- fluidPage(
  titlePanel("Caddisflies and Nutrient Spirals"),
  mainPanel(
    tabsetPanel(
      position = "left",
      tabPanel("Download Data",
               br()), # TODO: add inputs for date range, parameter, location,
      tabPanel("Visualize Data")
    )
  )
)

server <- function(input, output){
 
}

shinyApp(ui = ui, server = server)