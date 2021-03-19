
# shinyex_enfr

The goal of shinyex_enfr is to workshop a pattern for building bilingual English/French Shiny applications. The constraints are:

- Needs to have the ability to link to an English or French version (e.g., `?lang=en|fr`)
- Window title must be in the correct language
- In-app live switching of the language isn't strictly necessary but is useful for testing (current solution switches language based on a Shiny input value and does support this)
- Ability to theoretically support another language (e.g., Inuktitut) other than English or French for apps intended for clients/stakeholders in specific areas

See [the app in action](https://paleolimbot.shinyapps.io/shinyex_enfr) and [view the code](app.R).
