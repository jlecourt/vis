
# ---
# These global variables will be available 
# to all the transition functions 
# ---
paddingBottom = 20
width = 880
height = 600 - paddingBottom
duration = 750

x = d3.time.scale()
  .range([0, width])

y = d3.scale.linear()
  .range([height, 0])

color = d3.scale.category10()

line = d3.svg.line()
    .interpolate("basis")
    .x((d) -> x(d.date))
    .y((d) -> y(d.count))

area = d3.svg.area()
    .interpolate("basis")
    .x((d) -> x(d.date))

stack = d3.layout.stack()
  .values((d) -> d.values)
  .x((d) -> d.date)
  .y((d) -> d.count)
  .out((d,y0,y) -> d.count0 = y0)
  .order("reverse")

xAxis = d3.svg.axis()
  .scale(x)
  .tickSize(-height)
  .tickFormat(d3.time.format('%a %d'))

symbols = null

# Create the blank SVG the visualization will live in.
svg = d3.select("#vis").append("svg")
  .attr("width", width)
  .attr("height", height + paddingBottom)

# ---
# Called when the chart buttons are clicked.
# Hands off the transitioning to a new chart
# to separate functions, based on which button
# was clicked. 
# ---
transitionTo = (name) ->
  if name == "stream"
    streamgraph()
  if name == "stack"
    stacks()
  if name == "area"
    areas()

# ---
# This is our initial setup function.
# Here we setup our scales and create the
# elements that will hold our chart elements.
# ---
start = () ->

  min_date = d3.min(symbols, (d) -> d.values[0].date)
  max_date = d3.max(symbols, (d) -> d.values[d.values.length - 1].date)
  x.domain([min_date,max_date])

  # D3's axis functionality usually works great.
  # However, I was having some aesthetic issues
  # with the tick placement.
  # Here I extract out every other day - and 
  # manually specify these values as the tick 
  # values
  dates = symbols[0].values.map((v) -> v.date)
  index = 0
  dates = dates.filter (d) ->
    index += 1
    (index % 2) == 0

  xAxis.tickValues(dates)

  svg.append("g")
    .attr("class", "x axis")
    .attr("transform", "translate(0," + height + ")")
    .call(xAxis)
  
  g = svg.selectAll(".symbol")
    .data(symbols)
    .enter()

  sym = g.append("g")
    .attr("class", "symbol")

  sym.append("path")
    .attr("class", "area")
    .style("fill", (d) -> color(d.key))

  sym.append("path")
    .attr("class", "line")
    .style("stroke-opacity", 1e-6)

  createLegend()

  streamgraph()

# ---
# Code to transition to streamgraph.
#
# For each of these chart transition functions, 
# we first reset any shared scales and layouts,
# then recompute any variables that might get
# modified in other charts. Finally, we create
# the transition that switches the visualization
# to the new display.
# ---
streamgraph = () ->
  stack.offset("wiggle")

  stack(symbols)

  y.domain([0, d3.max(symbols[0].values.map((d) -> d.count + d.count0))])
    .range([height, 0])

  line.y((d) -> y(d.count0))

  area.y0((d) -> y(d.count0))
    .y1((d) -> y(d.count0 + d.count))

  t = svg.selectAll(".symbol")
    .transition()
    .duration(duration)
  
  t.select("path.area")
    .style("fill-opacity", 1.0)
    .attr("d", (d) -> area(d.values))

  t.select("path.line")
    .style("stroke-opacity", 1e-6)
    .attr("d", (d) -> line(d.values))

# ---
# Code to transition to Stacked Area chart.
# ---
stacks = () ->
  stack.offset("zero")
  stack(symbols)

  y.domain([0, d3.max(symbols[0].values.map((d) -> d.count + d.count0))])
    .range([height, 0])

  line.y((d) -> y(d.count0))

  area.y0((d) -> y(d.count0))
    .y1((d) -> y(d.count0 + d.count))

  t = svg.selectAll(".symbol")
    .transition()
    .duration(duration)

  t.select("path.area")
    .style("fill-opacity", 1.0)
    .attr("d", (d) -> area(d.values))

  t.select("path.line")
    .style("stroke-opacity", 1e-6)
    .attr("d", (d) -> line(d.values))

# ---
# Code to transition to Area chart.
#
# ---
areas = () ->
  g = svg.selectAll(".symbol")

  line.y((d) -> y(d.count0 + d.count))

  g.select("path.line")
      .attr("d", (d) -> line(d.values))
      .style("stroke-opacity", 1e-6)

  y.domain([0, d3.max(symbols.map((d) -> d.maxCount))])
    .range([height, 0])

  area.y0(height)
    .y1((d) -> y(d.count))

  line.y((d) -> y(d.count))

  t = g.transition()
    .duration(duration)

  t.select("path.area")
    .style("fill-opacity", 0.5)
    .attr("d", (d) -> area(d.values))

  t.select("path.line")
    .style("stroke-opacity", 1)
    .attr("d", (d) -> line(d.values))

# ---
#
# ---
showLegend = (d,i) ->
  d3.select("#legend svg g.panel")
    .transition()
    .duration(500)
    .attr("transform", "translate(0,0)")

# ---
#
# ---
hideLegend = (d,i) ->
  d3.select("#legend svg g.panel")
    .transition()
    .duration(500)
    .attr("transform", "translate(200,0)")

# ---
#
# ---
createLegend = () ->
  legendWidth = 240
  legendHeight = 245
  legend = d3.select("#legend").append("svg")
    .attr("width", legendWidth)
    .attr("height", legendHeight)

  legendG = legend.append("g")
    .attr("transform", "translate(200,0)")
    .attr("class", "panel")

  legendG.append("rect")
    .attr("width", legendWidth)
    .attr("height", legendHeight)
    .attr("rx", 4)
    .attr("ry", 4)
    .attr("fill-opacity", 0.5)
    .attr("fill", "white")

  legendG.on("mouseover", showLegend)
    .on("mouseout", hideLegend)

  keys = legendG.selectAll("g")
    .data(symbols)
    .enter().append("g")
    .attr("transform", (d,i) -> "translate(#{5},#{10 + 40 * (i + 0)})")

  keys.append("rect")
    .attr("width", 30)
    .attr("height", 30)
    .attr("rx", 4)
    .attr("ry", 4)
    .attr("fill", (d) -> color(d.key))

  keys.append("text")
    .text((d) -> d.key)
    .attr("text-anchor", "left")
    .attr("dx", "2.3em")
    .attr("dy", "1.3em")
  

# ---
# Function that is called when data is loaded
# Here we will clean up the raw data as necessary
# and then call start() to create the baseline 
# visualization framework.
# ---
display = (error, data) ->
  parse = d3.time.format("%x").parse

  filterer = {"Heating": 1, "Damaged tree": 1, "Noise": 1, "Traffic signal condition": 1, "General construction":1, "Street light condition":1}
  keys = data.map (d) -> d.key
  console.log(keys)

  # symbols = data[0..5]
  symbols = data.filter((d) -> filterer[d.key] == 1)
  symbols.forEach (s) ->
    s.values.forEach (d) ->
      d.date = parse(d.date)
      d.count = parseFloat(d.count)
    s.maxCount = d3.max(s.values, (d) -> d.count)

  symbols.sort((a,b) -> b.maxCount - a.maxCount)


  start()

# Document is ready, lets go!
$ ->

  # code to trigger a transition when one of the chart
  # buttons is clicked
  d3.selectAll(".switch").on "click", (d) ->
    d3.event.preventDefault()
    id = d3.select(this).attr("id")
    transitionTo(id)

  # load the data and call 'display'
  d3.json("data/all_reports.json", display)

