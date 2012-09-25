# Introduction

Spar, the *Single Page Application Rocketship*, is an opinionated framework that aims to ease single-page web-app development by addressing major challenges:

  * Asset organization
  * Compilation pipeline
  * Build & deployment support

Additionally, Spar provides templates & example projects for either a bare-bones project, or one with some of our favorite tools pre-included.

Under the hood, Spar is a Sprockets-based, Rails-derived project. Spar uses Sprockets to provide a powerful asset-pipeline, while stripping out legacy web-app support and introducing tools & patterns specific to single-page apps.

# Requirements

* Ruby 1.9.2-p125

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

    /public                   #File in here will be available to your application, but not managed as assets.
      /downloads              #File in here will include a 'Content-Disposition: attachment;' header if deployed to S3

    /vendor                   #Put external libraries like jquery or bootstrap here
      /javascripts
      /stylesheets
    
    config.yml                #ENV settings for development, staging, production
    README                    #your project's README
    
# Configuration

  `config.yml` defines your project's configuration for different environments. You may define any properties you like, which are available to you in all your asset files. 

  These settings may be overriden on a per-environment basis for `development`, `staging`, and `production` like so:

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

Both can be found at our [spar-examples](https://github.com/BoundlessLearning/spar-examples) repo.

# Deploying Your Spar App

Spar supports three different deployment methods out of the box:

* 'local': Deploy your app to a directory local to your computer.
* 's3': Deploy your app to an AWS S3 bucket.
* 'cloudfront': Deploy your app to an AWS S3 bucket and invalidate a Cloudfront distribution.

To deploy your app, run:

```bash
spar deploy poduction
```

You can pass any environment name to the deploy command, typically `staging` or `production`.

## Local Deployment

To deploy to a local directory, setup your config.yml file like so:

    default:    
      debug: true

    staging:
      debug: false
      deploy_strategy: local
      deploy_path: compiled/staging

    production:
      debug: false
      compress: true
      deploy_strategy: local
      deploy_path: compiled/production

 The deploy_path may be either a relative path in your application or a global path on your computer.

## S3 Deployment

To deploy to an S3 bucket, setup your config.yml file like so:

    default:    
      debug: true

    staging:
      debug: false

    production:
      debug: false
      compress: true
      deploy_strategy: s3
      aws_key: "my_access_key"
      aws_secret: "my+super+secret+access+key"
      deploy_bucket: "mysite.test.com"

You'll need to enter your own credentials. You can find your S3 credentials on the [AWS Security Credentials](https://portal.aws.amazon.com/gp/aws/securityCredentials) page. 

Next, you'll need visit the [AWS  S3 Console](https://console.aws.amazon.com/s3/home) and create a bucket to host your app. We suggest using the same as your fully qualified domain name. You should not use this bucket for anything else.

![click here](http://spar-screenshots.s3.amazonaws.com/s3_click_here.png)

![create bucket](http://spar-screenshots.s3.amazonaws.com/s3_create_bucket.png)

Specify your bucket in `config/production.rb`:

```ruby
    set :s3_bucket,               "app.example.com"
```

Next, you'll need to turn on [S3 Website Hosting](http://aws.typepad.com/aws/2011/02/host-your-static-website-on-amazon-s3.html) in the S3 console.

![bucket properties](http://spar-screenshots.s3.amazonaws.com/s3_bucket_properties.png)

![enable website](http://spar-screenshots.s3.amazonaws.com/s3_enable_website.png)

You'll need to create a new `CNAME` record. How this works is up to your hosting provider, but it should look something like this.

    app.example.com. IN CNAME app.example.com.s3-website-us-east-1.amazonaws.com.

### About Logging

You'll probably want to be able to log requests to your site. Even though your app uses cutting edge webscale tools like Airbrake, Loggly, Google Analytics, MixPanel, et al, eventually you'll want to know how many people hit you with IE6 or NoScript, and you gave them the middle finger.

Create a bucket log using the [AWS  S3 Console](https://console.aws.amazon.com/s3/home). Give it a name like `logs.example.com` and update either your app's CloudFront distribution or your app's S3 bucket to write its log files to this log bucket.

![enable logging](http://spar-screenshots.s3.amazonaws.com/s3_enable_logging.png)


## CloudFront Deployment

Cloudfront deployment is very similar to S3 deployment, but you need to add a cloudfront_distribution to your config file:

    default:    
      debug: true

    staging:
      debug: false

    production:
      debug: false
      compress: true
      deploy_strategy: cloudfront
      aws_key: "my_access_key"
      aws_secret: "my+super+secret+access+key"
      deploy_bucket: "mysite.test.com"
      cloudfront_distribution: "distribution+id"

Cloudfront will turn your fast site into a *really* fast site. From the [AWS  CloudFront Console](https://console.aws.amazon.com/cloudfront/home), create a new distribution *with the website form of your bucket name as the origin* and save the ID in your config.yml.

Take note of the **Domain Name** field (something like `d242ood0j0gl2v.cloudfront.net`). You will need to replace the CNAME you created earlier.

    app.example.com. IN CNAME d242ood0j0gl2v.cloudfront.net.

Now, every time you deploy, Spar will automatically issue CloudFront invalidation requests for index.html (and anything else without a hash value). CloudFront invalidations usually take around 8 minutes, but they can take quite a bit lot longer when Amazon is having problems.

# Issues & Bugs

Please use our Github [issue tracker](https://github.com/BoundlessLearning/spar/issues) for Spar.

# License

Spar is licensed under the terms of the MIT License, see the included LICENSE file.
