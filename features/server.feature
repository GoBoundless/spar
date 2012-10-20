Feature: Rack app that compiles on the fly
  In order to develop my app locally
  As a developer
  I want to run spar as a rack server

  Scenario: Serves haml files under /pages
    Given a dummy app
    When I visit "/index.html"
    Then I should see "Welcome to your new Spar app."

