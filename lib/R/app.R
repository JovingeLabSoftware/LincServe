library(shiny)
library(shinydashboard)
library(dplyr)


ip <- readRDS('~/tmp/ip.rds')

sidebar <- dashboardSidebar(
  sidebarMenu(
    menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard")),
    menuItem("Query", icon = icon("database"), tabName = "query",
             badgeLabel = "dev", badgeColor = "red"),
    menuItem("ExpSpect", icon = icon("bar-chart"), tabName = "expspect",
             badgeLabel = "dev", badgeColor = "red")
    
  )
)

body <- dashboardBody(
  tabItems(
    tabItem(tabName = "dashboard",
            
            # full data set
            fluidRow(
              box(
                title = "Full Dataset",
                valueBoxOutput("doc_count", width = 3),
                valueBoxOutput("cell_count", width = 3),
                valueBoxOutput("chem_count", width = 3),
                valueBoxOutput("gen_count", width = 3),
                width = 12, solidHeader = TRUE, status = "primary"
              )
            ),
            
            # gold only
            fluidRow(
              box(
                title = "Gold Instances",
                valueBoxOutput("g_doc_count", width = 3),
                valueBoxOutput("g_cell_count", width = 3),
                valueBoxOutput("g_chem_count", width = 3),
                valueBoxOutput("g_gen_count", width = 3),
                width = 12, solidHeader = TRUE, status = "primary"
              )
            ),
            
            # z-scores computed
            fluidRow(
              box(
                title = "Z-Scores Computed",
                valueBoxOutput("z_doc_count", width = 3),
                valueBoxOutput("z_cell_count", width = 3),
                valueBoxOutput("z_chem_count", width = 3),
                valueBoxOutput("z_gen_count", width = 3),
                width = 12, solidHeader = TRUE, status = "primary"
              )
            )
            
            
    ),
    tabItem(tabName = "query",
            h2("Query coming soon...")
    ),
    tabItem(tabName = "expspect",
            h2("ExpSpect coming soon...")
    )
    
  )
)


ui <- dashboardPage(
  dashboardHeader(title = "LINCS Dash"),
  sidebar,
  body
)


# Invalid color: lightblue. Valid colors are: red, yellow, aqua, blue, light-blue, green, navy, teal, olive, lime, orange, fuchsia, purple, maroon, black.

server <- function(input, output) { 

  # pull this info once when user acesses site
  cell_ids <- jsonlite::fromJSON(paste0('http://', ip, ':8092/LINCS1/_design/lincs/_view/cell_summary?group_level=2&inclusive_end=true&stale=false&connection_timeout=60000&skip=0'))
  pert_ids <- jsonlite::fromJSON(paste0('http://', ip, ':8092/LINCS1/_design/lincs/_view/pert_summary?group_level=3&inclusive_end=true&stale=false&connection_timeout=60000&skip=0'))

  cdf <- cbind.data.frame(do.call(rbind, cell_ids$rows$key), cell_ids$rows$value)
  pdf <- cbind.data.frame(do.call(rbind, pert_ids$rows$key), pert_ids$rows$value)
  names(cdf) <- c('variable', 'is_gold', 'value')
  names(pdf) <- c('variable', 'pname', 'is_gold', 'value')
  
  # full data set --------------------------------------------------------------
  output$doc_count <- renderValueBox({
    valueBox(
      formatC(sum(cdf$value), format = "d", big.mark = ','), 
      "Total Documents", icon = icon("database"),
      color = "green"
    )})

  output$cell_count <- renderValueBox({
    valueBox(
      formatC(length(unique(cdf$variable[!is.na(cdf$variable)])), format = "d", 
              big.mark = ','), "Cell Lines", icon = icon("table"),
      color = "aqua"
    )})
  
  output$chem_count <- renderValueBox({
    cc <- pdf %>% filter(variable == 'trt_cp' | variable == 'trt_lig') %>% 
      select(pname) %>% unlist %>% unique %>% length
    valueBox(
      formatC(cc, format = "d", 
              big.mark = ','), "Chemical Reagents", icon = icon("flask"),
      color = "yellow"
    )})
  
  output$gen_count <- renderValueBox({
    cc <- pdf %>% filter(variable == 'trt_sh' | variable == 'trt_sh.cgs' | variable == 'trt_oe' | variable == 'trt_oe.mut') %>% 
      select(pname) %>% unlist %>% unique %>% length
    valueBox(
      formatC(cc, format = "d", 
              big.mark = ','), "Genetic Reagents", icon = icon("edit"),
      color = "olive"
    )})
  
  
  # gold only data set --------------------------------------------------------------
  output$g_doc_count <- renderValueBox({
    ct <- cdf %>% filter(is_gold != 'FALSE') %>% select(value) %>% unlist %>% sum
    valueBox(
      formatC(ct, format = "d", big.mark = ','), 
      "Total Documents", icon = icon("database"),
      color = "green"
    )})
  
  output$g_cell_count <- renderValueBox({
    ct <- cdf %>% filter(!is.na(variable) & is_gold != 'FALSE') %>% select(variable) %>% unlist %>% unique %>% length
    valueBox(
      formatC(ct, format = "d", 
              big.mark = ','), "Cell Lines", icon = icon("table"),
      color = "aqua"
    )})
  
  output$g_chem_count <- renderValueBox({
    cc <- pdf %>% filter(is_gold != 'FALSE') %>% filter(variable == 'trt_cp' | variable == 'trt_lig') %>% 
      select(pname) %>% unlist %>% unique %>% length
    valueBox(
      formatC(cc, format = "d", 
              big.mark = ','), "Chemical Reagents", icon = icon("flask"),
      color = "yellow"
    )})
  
  output$g_gen_count <- renderValueBox({
    cc <- pdf %>% filter(is_gold != 'FALSE')  %>% filter(variable == 'trt_sh' | variable == 'trt_sh.cgs' | variable == 'trt_oe' | variable == 'trt_oe.mut') %>% 
      select(pname) %>% unlist %>% unique %>% length
    valueBox(
      formatC(cc, format = "d", 
              big.mark = ','), "Genetic Reagents", icon = icon("edit"),
      color = "olive"
    )})

  # z-scores computed data set --------------------------------------------------------------
  output$z_doc_count <- renderValueBox({
    # ct <- cdf %>% filter(is_gold != 'FALSE') %>% select(value) %>% unlist %>% sum
    valueBox(
      # formatC(ct, format = "d", big.mark = ','), 
      'TBD',      
      "Total Documents", icon = icon("database"),
      color = "green"
    )})
  
  output$z_cell_count <- renderValueBox({
    # ct <- cdf %>% filter(!is.na(variable) & is_gold != 'FALSE') %>% select(variable) %>% unlist %>% unique %>% length
    valueBox(
      # formatC(ct, format = "d", big.mark = ','), 
      'TBD',
      "Cell Lines", icon = icon("table"),
      color = "aqua"
    )})
  
  output$z_chem_count <- renderValueBox({
#     cc <- pdf %>% filter(is_gold != 'FALSE') %>% filter(variable == 'trt_cp' | variable == 'trt_lig') %>% 
#       select(pname) %>% unlist %>% unique %>% length
    valueBox(
      # formatC(cc, format = "d", big.mark = ','), 
      'TBD',
      "Chemical Reagents", icon = icon("flask"),
      color = "yellow"
    )})
  
  output$z_gen_count <- renderValueBox({
    # cc <- pdf %>% filter(is_gold != 'FALSE')  %>% filter(variable == 'trt_sh' | variable == 'trt_sh.cgs' | variable == 'trt_oe' | variable == 'trt_oe.mut') %>% 
      # select(pname) %>% unlist %>% unique %>% length
    valueBox(
      # formatC(cc, format = "d", big.mark = ','), 
      'TBD',
      "Genetic Reagents", icon = icon("edit"),
      color = "olive"
    )})
  
  
}

shinyApp(ui, server)


