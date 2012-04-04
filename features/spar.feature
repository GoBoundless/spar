Feature: Spar
  In order to generate a new spar app
  As a CLI
  I want to generate a bunch of files

  Scenario: Creating a new app
    When I run `spar test_app`
    Then the output should contain "A new Spar app has been created in test_app - Have Fun!"