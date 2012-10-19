Given /^a dummy app$/ do
  Dir.chdir "tmp" do
    `rm -rf dummy && spar new dummy`
    Dir.chdir "dummy" do
      Capybara.app = Spar.app
      Spar.settings["environment"] = "test"
    end
  end
end

When /^I visit "(.*?)"$/ do |path|
  visit path
end

Then /^I should see "(.*?)"$/ do |text|
  page.should have_content(text)
end
