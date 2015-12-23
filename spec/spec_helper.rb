$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'timecop'
require "codeclimate-test-reporter"
CodeClimate::TestReporter.start
require 'hitnmiss'
