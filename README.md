# Colour Extractor
Ruby script to extract the most common colours from an image

  1. Fetch the RGB values of every pixel 
  2. Group them using the DeltaE(2000) algorithm
  3. Continue to combine the colours until at least 10 are found
  4. Colours that are less than 0.5% of the total are discarded

---

## Pre-requisites
ImageMagick  
`brew install imagemagick'

--- 

## Run the app
`bundle install`  
`chmod +x app.rb`  
`./app.rb https://images.pexels.com/photos/3844788/pexels-photo-3844788.jpeg`  
This script will write an image output.jpg containing the top 10 colours extracted from the input image

### Options
-p --proportional This flag will create the colours in the output image in proportion to how much in the source image they appear
--- 

```
r1 = Color::RGB.by_hex('150c11')
r2 = Color::RGB.by_hex('140b10')
puts DeltaE.rgb_distance(r1, r2) * 100
```
