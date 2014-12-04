#!/usr/bin/env ruby
require 'rdf/microdata'
require 'rdf/turtle'
require 'json/ld'

BASE = "https://w3c.github.io/microdata-rdf/tests/"
graph = RDF::Graph.load("./index.html",
  :base_uri => BASE,
  :registry => "./test-registry.json")

# Turtle version
ttl = graph.dump(:ttl,
  :base_uri => BASE,
  :prefixes => {
    rdfs: "http://www.w3.org/2000/01/rdf-schema#",
    rdft: "http://www.w3.org/ns/rdftest#",
    mf:   "http://www.w3.org/2001/sw/DataAccess/tests/test-manifest#",
    mq:   "http://www.w3.org/2001/sw/DataAccess/tests/test-query#"
  }
)
File.open("./manifest.ttl", "w") do |f|
  f.write(ttl.lines.to_a[1..-1].join(""))
end

# JSON-LD version
File.open("./manifest.jsonld", "w") do |f|
  JSON::LD::API.fromRDF(graph) do |expanded|
    JSON::LD::API.frame(expanded, "./manifest-frame.jsonld") do |framed|
      json = framed.to_json(JSON::LD::JSON_STATE).gsub(BASE, "")
      f.write json
    end
  end
end
