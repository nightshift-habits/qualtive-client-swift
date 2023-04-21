Pod::Spec.new do |spec|

  spec.name         = "Qualtive"
  spec.version      = "1.4.1"
  spec.summary      = "Qualtive Client Library for Swift."
  spec.author       = { "Qualtive" => "support@qualtive.io" }
  spec.homepage     = "https://qualtive.io"
  spec.description  = "The Qualtive client library for Swift adds support for sending feedback from your native app on Apple platforms to [Qualtive](qualtive.io)."
  # spec.screenshots  = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"

  spec.swift_version = "5.3"

  spec.ios.deployment_target = "9.0"
  spec.osx.deployment_target = "10.10"
  spec.watchos.deployment_target = "2.0"
  spec.tvos.deployment_target = "9.0"

  spec.source        = { :git => "https://github.com/nightshift-habits/qualtive-client-swift.git", :tag => "#{spec.version}" }
  spec.source_files  = "Sources/Qualtive/**/*.swift"

  spec.license      = { :type => 'MIT License', :text => <<-LICENSE
MIT License

Copyright (c) 2021 Nightshift Habits AB

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
LICENSE
  }
end
