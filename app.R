# app.R
library(shiny)

# Define UI for application that draws a histogram
ui <- fluidPage(
  # Application title
  titlePanel("Old Faithful Geyser - Watchtower"),

  # Sidebar with a slider input for number of bins
  sidebarLayout(
    sidebarPanel(
      sliderInput(
        inputId = "bins",
        label   = "Number of bins:",
        min     = 1,
        max     = 50,
        value   = 30
      )
    ),

    # Show a plot of the generated distribution
    mainPanel(
      plotOutput(outputId = "distPlot")
    )
  )
)

# Define server logic to draw a histogram
server <- function(input, output) {
  output$distPlot <- renderPlot({
    # Calculate breakpoints for the histogram
    bins <- seq(
      from = min(faithful$eruptions),
      to   = max(faithful$eruptions),
      length.out = input$bins + 1
    )

    # Draw the histogram
    hist(
      x        = faithful$eruptions,
      breaks   = bins,
      col      = "darkgray",
      border   = "white",
      xlab     = "Eruption duration (minutes)",
      main     = "Histogram of Eruption Durations"
    )
  })
}

# Run the application
shinyApp(ui = ui, server = server)

