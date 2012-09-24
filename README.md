# Spar

(Single-Page App Rocketship)

## Introduction

Spar is an opinionated framework that aims to ease single-page web-app development by addressing major challenges:

  * Asset organization
  * Compilation pipeline
  * Build & deployment support

Additionally, Spar provides templates & example projects for either a bare-bones project, or one with some of favorite tools pre-included.

Under the hood, Spar is a Rails-derived project, taking advantage of the powerful asset-pipeline, while stripping out legacy web-app support and introducing tools & patterns specific to single-page apps.

## Requirements

    TODO. Ruby? Rbenv? Powify?

## Installing Spar

    gem install spar
    rbenv rehash

## Getting Started

  Issue the following command to create a new Spar project:

    spar myapp
    cd myapp
    bundle install
    powify create www.myapp
    powify browse www.myapp

  At this point, you'll see the default Spar page... congrats!

## App Organization

  Spar apps are organized into the follow folders:

    /app                #assets that make your app
      /images
      /javascripts
        application.js.coffee
      /stylesheets
        application.css.sass
      /pages
        index.haml
    
    /config
      /environments     #configs per deployment
        development.rb
        staging.rb
        production.rb

    /lib                #I have no idea
    /public             #I have no idea
    /vendor             #I have no idea
    Gemfile             #optional installed pipeline gems
    README              #optional project readme
    Rakefile            #I have no idea
    config.ru           #I have no idea

## The Pipeline

All Spar asset files are processed according to their extensions, i.e., myfile.js.coffee.spar will first have symbols replaced according to the current Spar environment, and then passed through a Coffeescript compiler, ultimately outputting myfile.js.

Multiple assets can be combined into one greater asset using some magic.

Likewise, myfile.css.sass goes through a similar transformation, and multiple CSS assets can be compiled into one greater asset.

## Example & Bootstrap Apps

Included with Spar are two example applications. 

The first is the quintessential TODO application as popularized by http://addyosmani.github.com/todomvc/

The second, is a bootstrap application containing our favorite tools for making web-sites:

  - Coffescript
  - jQuery
  - Backbone

as well as:

  - SASS
  - Compass
  - Twitter Bootstrap

## Issues & Bugs

Please use the Github issue tracker for Spar, https://github.com/BoundlessLearning/spar/issues

## License

Spar is licensed under the terms of the MIT License, see the included LICENSE file.








