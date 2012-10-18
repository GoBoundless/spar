Feature: Spar
  In order to generate a new spar app
  As a CLI
  I want to generate a bunch of files

  Scenario: Creating a new app
    When I run `spar new test_app`
    Then the output should contain:
      """
            create  test_app
            create  test_app/README
            create  test_app/app/images/spar.png
            create  test_app/config.yml
            create  test_app/static/.gitkeep
            create  test_app/static/downloads/.gitkeep
            create  test_app/static/favicon.ico
            create  test_app/vendor/.gitkeep
            create  test_app/vendor/javascripts/.gitkeep
            create  test_app/vendor/stylesheets/.gitkeep
             exist  test_app
            create  test_app/app/stylesheets/application.css.sass
             exist  test_app
            create  test_app/app/pages/index.html.haml
             exist  test_app
            create  test_app/app/javascripts/application.js.coffee
      """
