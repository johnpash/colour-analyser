require 'color'

module ColorCombinator
  def self.run(colours)
    ################################################################################
    # iterate through the colour array, comparing each RGB value with all that follow
    # if the colour difference (DeltaE) is within a certain distance
    # then add the `num` value of the smaller of the two, then delete it
    # effectively merging them under a single RGB value

    pixel = Struct.new(:rgb, :num, :pct)

    # `groups` is a hash with similar colours grouped using the DeltaE algorithm
    grouped = {}
    (0...colours.size).each do |i|
      pix = colours[i]
      next unless pix.respond_to?(:rgb)

      rgb1 = Color::RGB.new(*pix.rgb)

      time = Benchmark.measure do
        ((i + 1)...colours.size).each do |j|
          pix2 = colours[j]
          next unless pix2.respond_to?(:rgb)

          rgb2 = Color::RGB.new(*pix2.rgb)

          lab1 = rgb1.to_lab.values
          lab2 = rgb2.to_lab.values
          delta = DeltaE.distance(lab1, lab2) * 100

          if delta < 15
            pix.num += pix2.num
            colours.delete_at(j)
          end

          grouped[pix.rgb] = pixel.new(pix.rgb, pix.num)
        end
      end
      puts time
    end

    # again, drop the hash keys and return only the values
    # they were useful for quick lookups, but we are only interested in the Pixels
    grouped.values
  end
end
