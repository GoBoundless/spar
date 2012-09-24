# Spar

The *Single Page Application Rocketship*

## Introduction

Spar is an opinionated framework that aims to ease single-page web-app development by addressing major challenges:

  * Asset organization
  * Compilation pipeline
  * Build & deployment support

Additionally, Spar provides templates & example projects for either a bare-bones project, or one with some of favorite tools pre-included.

Under the hood, Spar is a Rails-derived project, taking advantage of the powerful asset-pipeline, while stripping out legacy web-app support and introducing tools & patterns specific to single-page apps.

## Requirements

* Ruby 1.9.2-p125

## Installing Spar

```bash
$ gem install spar
````

If using `rbenv`:

```bash
rbenv rehash
```

## Getting Started

  Issue the following command to create a new Spar project:

```bash
$ spar myapp
$ cd myapp
$ bundle install
$ powify create www.myapp
$ powify browse www.myapp
```

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

## Deploying Your Spar App

### GitHub Pages
### Heroku

### Amazon Web Services

Spar has full support for S3 and CloudFront out of the box. First, add your AWS credentials to `config/production.rb`. You can look these up on the [AWS Security Credentials](https://portal.aws.amazon.com/gp/aws/securityCredentials) page.

```ruby
    set :acccess_key_id,          "my_access_key"
    set :secret_access_key,       "my+super+secret+access+key"
```

Next, you'll need a bucket to host your app. We suggest using the same as your fully qualified domain name. You should not use this bucket for anything else.

[screenshots of bucket creation process]

Specify your bucket in `config/production.rb`:

```ruby
    set :s3_bucket,               "app.example.com"
```

Next, you'll need to turn on [S3 Website Hosting](http://aws.typepad.com/aws/2011/02/host-your-static-website-on-amazon-s3.html) in the S3 console.

[screenshots of enabling website hosting]

You'll need to create a new `CNAME` record. How this works is up to your hosting provider, but it should look something like this.

    app.example.com. IN CNAME app.example.com.s3-website-us-east-1.amazonaws.com.

#### CloudFront

From here, it's easy to turn your fast site into a *really* fast site. From the [AWS  CloudFront Console](https://console.aws.amazon.com/cloudfront/home), create a new distribution *with the website form of your bucket name as the origin* and save the ID in `config/production.rb`.

```ruby
    set :cloudfront_distribution, "K9SYZF479EXMUAWH"
```
Take note of the **Domain Name** field (something like `d242ood0j0gl2v.cloudfront.net`). You will need to replace the CNAME you created earlier.

    app.example.com. IN CNAME d242ood0j0gl2v.cloudfront.net.

Now, every time you deploy, Spar will automatically issue CloudFront invalidation requests for index.html (and anything else without a hash value). CloudFront invalidations usually take around 8 minutes, but they can take quite a bit lot longer when Amazon is having problems.

#### About Logging

You'll probably want to be able to log requests to your site. Even though your app uses cutting edge webscale tools like Airbrake, Loggly, Google Analytics, MixPanel, et al, eventually you'll want to know how many people hit you with IE6 or NoScript, and you gave them the middle finger.

Create a bucket log using the [AWS  S3 Console](https://console.aws.amazon.com/s3/home). Give it a name like `logs.example.com` and update either your app's CloudFront distribution or your app's S3 bucket to write its log files to this log bucket.

### Apache, NginX, Lighttpd, etc

`rake assets:precompile` populates the `public/` directory with each view in its own `index.html`, which any web server should be able to serve with minimal configuration.

## Issues & Bugs

Please use the Github issue tracker for Spar, https://github.com/BoundlessLearning/spar/issues

## License

Spar is licensed under the terms of the MIT License, see the included LICENSE file.
