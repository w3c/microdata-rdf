#!/usr/bin/env ruby
# Add a test to the test manifest
require 'getoptlong'
require 'strscan'

opts = GetoptLong.new(
  [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
  [ '--num', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--comment', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--data', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--result', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--negative', GetoptLong::NO_ARGUMENT ],
)

num = comment = data = result = negative = nil

section_start = %r(.* id="positive-tests")m

opts.each do |opt, arg|
  case opt
  when '--help'
    puts %(usage: add-test opts
      --help      - this message
      --num       - test number, defaults to last number
      --negative  - negative test, positive otherwise
      --comment   - REQUIRED: test comment
      --data      - input file, defaults to num.html
      --result    - result file, defaults to num.ttl
    )
  when '--num' then num = arg.to_i
  when '--negative' then section_start = %r(.* id="negative-tests")m
  when '--comment' then comment = arg
  when "--data" then data = arg
  when "--resuit" then result = arg
  end
end

raise "Required argument --comment missing" if comment.nil?

input = StringScanner.new(File.read("./index.html"))

# scan to section start
output = input.scan(section_start)
output += input.scan_until(%r(</h2>\n)m)

# scan until last test, counting existing tests
num_tests = 0
while this_test = input.scan_until(%r(<!-- End Test Description -->\n)m)
  num_tests += 1
  output += this_test
end

num ||= num_tests + 1
num_str = "%.4d" % num
data ||= "#{num_str}.html"
result ||= "#{num_str}.ttl"

# Create test files, if they don't exist
File.open(data, "w") unless File.exist?(data)
File.open(result, "w") unless File.exist?(result)

# Add test
output += %(
<!-- Start Test Description -->
<div itemprop="entries"
     itemscope="true"
     itemtype="http://www.w3.org/2001/sw/DataAccess/tests/test-manifest#ManifestEntry"
     class="test-entry">
  <span itemprop="name">Test #{num_str}</span>:
  <span itemprop="http://www.w3.org/2000/01/rdf-schema#comment"
    >#{comment}</span>
  (
  <span itemprop="action"
        itemscope="true"
        itemtype="http://www.w3.org/2001/sw/DataAccess/tests/test-query#QueryTest">
    <a itemprop="data" href="#{data}">input</a>
  </span> |
  <a itemprop="result" href="#{result}">result</a>
  <meta itemprop="positiveTest" content="true"/>
  )
</div>
<!-- End Test Description -->
)

output += input.rest

puts output