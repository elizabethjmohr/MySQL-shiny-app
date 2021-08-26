library(shiny)
library(rhandsontable)

params <- c("Nitrate + Nitrate", "Nitrate", "Nitrite","Ammonium", "SRP", "Sulfate", "DOC", "Copper")
locations <- c(paste("SAM", LETTERS[1:15]), "Effluent Reservoir", "16 Inflow Line", "Tap Water", "ASW Concentrate", "Cherry Creek")
labData = data.frame(
  SampleID = rep("SampleID", 10),
  Parameter = factor("Nitrate", levels = params),
  Value = 1
)

sampleMetadata = data.frame(
  SampleID = rep("SampleID", 10),
  Date = Sys.Date(),
  Time = "00:00",
  Location = factor("SAM A", levels = locations),
  Notes = "NA"
)

loggerDeployments = data.frame(
  SerialNo = rep(as.integer(123456), 10),
  Location = factor("SAM A", levels = locations),
  DeploymentDate = Sys.Date(),
  DeploymentTime = "00:00",
  RetrievalDate = Sys.Date(),
  RetrievalTime = "00:00"
)

ui <- fluidPage(
  titlePanel("Caddisflies and Nutrient Spirals Data Entry"),
  mainPanel(
    tabsetPanel(
      position = "left",
      tabPanel("Enter Sample Metadata",
               br(),
               rHandsontableOutput("metadataHot"),
               actionButton("submitMetadata", "Submit")),
      tabPanel("Log a Logger Deployment",
               br(),
               rHandsontableOutput("deploymentsHot"),
               actionButton("submitLoggerDeployment", "Submit")),
      tabPanel("Enter Lab Data",
               br(),
               rHandsontableOutput("labDataHot"),
               selectInput("lab", 
                           label = "Select Lab", 
                           choices = list("FLBS" = "FLBS", "Energy Labs" = "Energy Labs", "MSU-EAL" = "MSU-EAL"),
                           selected = "Energy Labs"),
               dateInput("analysisDate", 
                         label = "Analysis Date", 
                         value = Sys.Date()),
               textInput("labReportFilename",
                         label = "Laboratory Report Filename", 
                         value = "Enter name of data file received from lab..."),
               br(),
               actionButton("submitLabData", "Submit")),
      tabPanel("Upload Logger Data",
               br(),
               fileInput("loggerFile",
                         label = "Upload a logger file"),
               actionButton("submitLoggerData", "Submit")),
      tabPanel("Upload Files",
               br(),
               fileInput("file",
                         label = "Upload a file"),
               actionButton("submitFile", "Submit")),
      tabPanel("Download Data")
    )
  )
)

server <- function(input, output){
  output$metadataHot <- renderRHandsontable({
    rhandsontable(sampleMetadata, rowHeaders = NULL, width = 800, height = 300) %>%
      hot_col(col = "Location", type = "dropdown", source = locations) %>%
      hot_cols(colWidths = c(100,100,100,150,300))
  })
  
  output$deploymentsHot <- renderRHandsontable({
    rhandsontable(loggerDeployments, rowHeaders = NULL, width = 1000, height = 300) %>%
      hot_col(col = "Location", type = "dropdown", source = locations) %>%
      hot_cols(colWidths = c(100,150,120,120,100, 100))
  })
  
   output$labDataHot <- renderRHandsontable({
    rhandsontable(labData, rowHeaders = NULL, width = 500, height = 300) %>%
      hot_col(col = "Parameter", type = "dropdown", source = params) %>%
      hot_cols(colWidths = c(100,150,50))
  })
  

  formData <- reactive({
    
  })
  observeEvent(input$submitLabData, {
    saveLabData(formData())
  })
  
}

shinyApp(ui = ui, server = server)