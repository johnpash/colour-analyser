#!ruby
require 'benchmark'
require 'color'
require 'mini_magick'
require 'paint'
require 'pry-nav'
require 'pry'
require './lib/combine_colours'
require './lib/delta_e'

# `Pixel` struct is a handy container that's slightly easier to use than a hash
pixel = Struct.new(:rgb, :num, :pct)

# Get image url from command line (or use default)
file = ARGV.first || 'input.jpg'

# setting this to true will display the stripes relative to their occurance
# when false, each stripe is equal height
proportional = !(ARGV & ['--proportional', '-p']).empty?

begin
  img = MiniMagick::Image.open(file)
rescue OpenURI::HTTPError
  img = MiniMagick::Image.open(file_alt) if file_alt
end

height = img.height
width = img.width
img.resize '1000' if height > 1000 || width > 1000
total_pixels = height * width

# get_pixels returns an array of arrays containing the RGB values of each pixel
# [
#   [
#     [255, 53, 6], [1, 123, 43], [2, 255, 255]
#   ],
#   [
#     [23, 12, 51], [3, 10, 112], [54, 255, 42]
#   ]
# ]
pixels = img.get_pixels

# flatten(1) flattens only the first layer of arrays
# the end result is a single array of arrays. this makes it easier to iterate later on
pixels.flatten!(1)

################################################################################
# `matrix` is a hash where the pixel data collated
# hash keys are an RGB array -> [n, n, n]
# values are a Pixel struct
# {
#   [255, 255, 255] => <Pixel:struct>,
#   [102, 143, 201] => <Pixel:struct>
#   ... etc
# }
matrix = {}
pixels.each do |rgb|
  # create default Pixel with RGB value and 1 as the count(num)
  pix = pixel.new(rgb, 1, 0)

  # if rgb exists in the matrix, increment num
  pix.num = matrix[rgb].num + 1 if matrix.key?(rgb)

  # save value in matrix
  matrix[rgb] = pix
end

# the hash keys are no longer needed, only the values: Pixels
# this changes `matrix` from a Hash to an Array
matrix = matrix.values

# sort by the most occurances of each RGB triad
colours = matrix.sort_by(&:num).reverse

iterations = 0
prev_colours = colours
while colours.size > 10
  iterations += 1
  break if iterations > 100

  puts "unique colours: #{colours.size}"
  time = Benchmark.measure do
    colours = ColorCombinator.run(colours)
  end
  puts time

  # If the final iteration returns less than 10 colours, use the penultimate set
  if colours.size < 10
    puts 'fewer than 10 colours found!'
    colours = prev_colours
    break
  end

  prev_colours = colours
end

puts "#{colours.size} found in #{iterations} iterations"

################################################################################
# this is where the magicK happens...

# MiniMagick::Tool is a low-level api to ImageMagick
# it essentially creates the command-line arguments programmatically
# see: https://legacy.imagemagick.org/Usage/draw/#image
outimage = MiniMagick::Tool::Magick.new
outimage.size '1000x1000'
outimage << 'xc:white'

# initialise coordinates for drawing stripes on the output image
x0 = 0
x1 = 1000
y0 = 0
y1 = 0

# calculate the percentage of total pixels that each group consists of
colours.each { |group| group.pct = group.num / total_pixels.to_f }

# then sort by percentage largest -> smallest
colours.sort_by!(&:pct).reverse!

# draw 10 stripes in each colour
colours[0..10].each do |colour|
  rgb = Color::RGB.new(*colour.rgb)
  outimage.fill "rgb(##{rgb.hex})"

  pct = (colour.num / total_pixels.to_f) * 100
  next if pct < 0.5

  puts Paint[rgb.hex, :inverse, rgb.hex] + " #{rgb.hex} #{pct.round(2)}"

  # amount to shift on y-axis
  ymov = proportional ? 100 * pct : 100
  y1 += ymov

  # append draw command
  draw = "rectangle #{x0},#{y0} #{x1},#{y1}"
  outimage.draw draw

  # shift y0 for next iteration
  ymov = proportional ? 100 * pct : 100
  y0 += ymov
end

outimage << 'output.jpg'
puts outimage.args.join ' '
outimage.call

palette = colours[0..10].filter_map do |colour|
  pct = colour.pct * 100
  next if pct < 0.5

  rgb = Color::RGB.new(*colour.rgb)
  hsl = rgb.to_hsl.to_a.map { |d| (d * 100).to_i }

  {
    hex: "##{rgb.hex}",
    r: colour.rgb[0],
    g: colour.rgb[1],
    b: colour.rgb[2],
    h: hsl[0],
    s: hsl[1],
    l: hsl[2],
    pct: pct.round(2)
  }
end

puts palette
