# Introduction

Spar, the *Single Page Application Rocketship*, is an opinionated framework that aims to ease single-page web-app development by addressing major challenges:

  * Asset organization
  * Compilation pipeline
  * Build & deployment support

Additionally, Spar provides templates & example projects for either a bare-bones project, or one with some of our favorite tools pre-included.

Under the hood, Spar is a Sprockets-based, Rails-derived project. Spar uses Sprockets to provide a powerful asset-pipeline, while stripping out legacy web-app support and introducing tools & patterns specific to single-page apps.

# Requirements

* Ruby 1.9.2 or greater (preferably 1.9.3).

# Installing Spar

```bash
$ gem install spar
````

If using `rbenv`:

```bash
$ rbenv rehash
```

# Getting Started

  Issue the following command to create a new Spar project:

```bash
$ spar new myapp
$ cd myapp
$ spar server
```
  Your app will now be available at [http://localhost:8888](http://localhost:8888)

# Organization

  Spar apps are organized into the following folders and files:

    /app                      #Compiled assets that make your app
      /images
      /javascripts
        application.js.coffee #Your main JS output
      /stylesheets
        application.css.sass  #Your main CSS output
      /pages
        index.html.haml       #Your single, root HTML page

    /static                   #File in here will be available to your application, but not managed as assets.
      /downloads              #File in here will include a 'Content-Disposition: attachment;' header if deployed to S3

    /vendor                   #Put external libraries like jquery or bootstrap here
      /javascripts
      /stylesheets
    
    config.yml                #ENV settings for development, staging, production
    README                    #your project's README
    
# Configuration

  `config.yml` defines your project's configuration for different environments. You may define any properties you like, which are available to you in all your asset files. 

  These settings may be overriden on a per-environment basis for `development`, `staging`, and `production` like so:

```yaml
default:    
  debug: true
  my_app_name: My App!
  my_api: http://localhost:8080

staging:
  debug: false

production:
  debug: false
  compress: true
  my_api: http://production-api.mysite.com
```

  Spar respects the following known configuration options:

  - `debug`: true/false, includes JS files individually for easier debugging
  - `digest`: true/false, adds MD5 hashes to end of filenames for proper cache busting in deploys
  - `compress`: true/false, JS and CSS compression (uglify, and yahoo UI CSS compressor)

# Asset Pipeline

All asset files in the `app` directory are transformed through the Spar asset pipeline. Transformation first occurs for configuration properties defined in `config.yml`, followed by JS/CSS asset-compilation and composition.

## Configuration Property Replacement

First, configuration property substitution takes place according to your `config.yml` file. For instance, if your `index.html.haml` looks like this:

```haml
%html
  %head
    %title [{ my_app_name }]
```
it transforms to become:

```haml
%html
  %head
    %title My App!
```

## Compilation

After Spar performs configuration replacement, it then process files according to their extensions.

Inlcuded with Spar are transformations from:

- `file.html.haml` => `file.html`
- `file.js.coffee` => `file.js`
- `file.css.sass` => `file.css`
- `file.css.less` => `file.less`

## Dependency Management

Multiple Javascript (or CSS) files can be merged into a single file using the `require` and `require_tree` pre-processor directives.

If you want to serve one file, say `application.js`, that includes the content of multiple JS files, you may define an `application.js.coffee` like so:

```coffeescript
# This file will be compiled into application.js, which 
# will include all the files below required below

# The require directive can include individual file assets
# For instance, to include the compiled output of utils.js.coffee
#= require utils

# You can also recursively includes entire directories 
# using the require_tree directive
#= require_tree ./controllers
#= require_tree ./models
#= require_tree ./views
```
Stylesheet files are composed similarly, however directives should be placed in CSS/SASS comments appropriately:

```css
/*= require buttons.css */
```

## Deploy Directive
Most Spar apps will compile into a single `application.js` and `application.css` file, each including the `deploy` directive to ensure it is deployed.

If you wish to deploy additional root-level asset files, you may instruct Spar to do so by adding a `deploy` directive at the top of the file like so:

```coffeescript
#= deploy
```

Or, in CSS:

```css
/*= deploy */
```
You only need to do this for additional root-level Javascript and CSS based files, as Spar deploys all images, pages, and static files automatically.

# Example Spar Applications

For your reference, and to build on top of, we've created two example applications using Spar.

The first is the quintessential TODO application as popularized by [addyosmani](http://addyosmani.github.com/todomvc/). The second, is a bootstrap application containing some of our favorite tools to kick-start the pretty (jQuery, Backbone, and Twitter Bootstrap).

Both can be found at our [spar-examples](https://github.com/GoBoundless/spar-examples) repo.

# Deploying Your Spar App

Spar supports three different deployment methods out of the box:

* `local`: Deploy your app to a directory local to your computer.
* `s3`: Deploy your app to an AWS S3 bucket.
* `cloudfront`: Deploy your app to an AWS S3 bucket and invalidate a Cloudfront distribution.

To deploy your app, run:

```bash
spar deploy poduction
```

You can pass any environment name to the deploy command, typically `staging` or `production`.

## Local Deployment

To deploy to a local directory, setup your `config.yml` file environments like so:

```yaml
default:    
  debug: true

staging:
  deploy_strategy: local
  deploy_path: compiled/staging

production:
  deploy_strategy: local
  deploy_path: compiled/production
```

 The `deploy_path` may be either a relative path in your application or a global path on your computer.

## S3 Deployment

To deploy to an S3 bucket, setup your environments like so:

```yaml
production:
  deploy_strategy: s3
  aws_key: "my_access_key"
  aws_secret: "my+super+secret+access+key"
  deploy_bucket: "mysite.test.com"
```

Now Spar will dpeloy your app directly to an S3 bucket. To learn more and see how to setup an S3 bucket as a website, see the (S3 Deployment Wiki Page)[https://github.com/BoundlessLearning/spar/wiki/S3-Deployment]


## CloudFront Deployment

For details on Cloudfront deploys please see the (Cloudfront Deployment Wiki Page)[https://github.com/BoundlessLearning/spar/wiki/Cloudfront-Deployment]

# Issues & Bugs

Please use our Github [issue tracker](https://github.com/BoundlessLearning/spar/issues) for Spar.

# License

Spar is licensed under the terms of the MIT License, see the included LICENSE file.
