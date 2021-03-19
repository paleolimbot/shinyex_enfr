
library(shiny)
library(shiny.i18n)
library(shinyjs)

# Translations are defined in translation.json. I'm using "key" as the
# key language, but you could omit this an use "en" or "fr" as the key
# language as well. I like the ability to abbreviate the key because there
# are some longer bits (like the text of an "about" page) where using the
# english version as a "key" is problematic.
i18n <- Translator$new(translation_json_path = "translation.json")

# Set the default translation language to the first non-key language
i18n$set_translation_language(setdiff(i18n$get_languages(), "key")[1])

# Use i18n$t("key_value") for any user-facing text in the ui
ui <- fluidPage(
  useShinyjs(),
  usei18n(i18n),

  titlePanel(i18n$t("window_title")),
  sidebarLayout(
    sidebarPanel(
      # This could also be a radioButtons or selectInput, with inputId = "lang",
      # but in my app I need the flexibility to have these be other html elements
      # in order to make it look pretty
      div(
        a(href = "javascript: Shiny.setInputValue('lang', 'fr')", "Fr"),
        a(href = "javascript: Shiny.setInputValue('lang', 'en')", "En")
      )
    ),
    mainPanel(
      verbatimTextOutput("lang_dummy"),
      verbatimTextOutput("test_output")
    )
  )
)

server <- function(input, output, session) {

  # Use i18n$t("key_value") for any user-facing text in the server
  output$test_output <- renderText({
    i18n$t("window_title")
  })

  # One way to get the browser's idea of what the language is
  # this won't set the input value right away; code needs to treat this like
  # an input value that could be set by the user at any time. Also need
  # a js handler to change the window title because doing this from R at
  # runtime is otherwise not possible
  runjs("
    var usr_lang_initial_auto =  window.navigator.userLanguage || window.navigator.language;
    Shiny.setInputValue('lang_initial_auto', usr_lang_initial_auto);
    Shiny.addCustomMessageHandler('changetitle', function(x) { document.title = x });
  ")

  # An empty output that is rendered initially and when 'lang_initial_auto'
  # is changed (on page load)
  output$lang_dummy <- renderText({
    query <- parseQueryString(session$clientData$url_search)
    new_lang <- NULL
    has_initial_lang <- exists("lang_initial", session$userData)

    if (!has_initial_lang && !is.null(query$lang)) {
      new_lang <- query$lang
      session$userData$lang_initial <- query$lang

    } else if (!has_initial_lang && !is.null(input$lang_initial_auto)) {
      # input value will be something like en-CA
      new_lang <- substr(input$lang_initial_auto, 1, 2)

      # if the user's language isn't in the translation key, use the first
      # non-key language
      if (!(new_lang %in% i18n$get_languages())) {
        new_lang <- setdiff(i18n$get_languages(), "key")[1]
      }

      session$userData$lang_initial <- new_lang
    } else if (!exists("lang", session$userData)) {
      new_lang <- setdiff(i18n$get_languages(), "key")[1]
    }

    if (!is.null(new_lang)) {
      session$userData$lang <- new_lang
      update_lang(session, new_lang)
      updateQueryString(paste0("?lang=", new_lang), mode = "replace")

      # window title doesn't quite work with i18n$t()
      session$sendCustomMessage(
        "changetitle",
        i18n$get_translations()["window_title", new_lang]
      )
    }
  })

  # Observe language change from updated Shiny input
  observeEvent(input$lang, {
    new_lang <- input$lang
    update_lang(session, new_lang)
    updateQueryString(paste0("?lang=", new_lang), mode = "replace")
    session$userData$lang <- new_lang

    # window title doesn't quite work with i18n$t()
    session$sendCustomMessage(
      "changetitle",
      i18n$get_translations()["window_title", new_lang]
    )
  })
}

shinyApp(ui, server)
