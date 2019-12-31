# Brazil Forest Fires 2018
The Amazon rainforest is the world's largest tropical rainforest. Something people have been saying to bring attention to why we should care about the deforestation and forest fires is that "One in five breaths we take comes from the Amazon". The point is, the Amazon is important and must be protected seeing as how it's being threatened.

## App
The app in development is a Shiny app. With a focus on spacial visualization, the app will use ggspacial to create various visualizations of the amount of forest fires in different regions at various times.

## Run Locally
Shiny apps can be run locally in RStudio using the following code:

library(shiny)
runGitHub("Brazil-Forest-Fires", "deltalite")

Use the command install.packages("<package name>") to install any packages you don't have locally. If you've downloaded the repo, RStudio should also prompt you to install any packages you are missing.

## Visualization
This will not be my first Shiny app, but will certainly be a good exercise for visualizing spatial data, as well as using other graphs to compare the impact in different regions. 