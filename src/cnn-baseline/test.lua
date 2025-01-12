require 'SunRelDataset'
libimage = require 'image'
utils = require 'utils'

--print('qt', qt)
--[[
if not qt then
   libimage.display = function() end
end
--]]

dataset = SunRelDataset{mode='train'}

print('#dataset', dataset:size())

idx = torch.random(dataset:size())
data = dataset:get(idx)

print(data.subject, data.predicate, data.object)

subbox = data.subjectbbox
objbox = data.objectbbox

unionbox = SunRelDataset.bboxUnion(subbox, objbox)
unionbox = data.unionbox

lineWidth = 6

vggmeanRGB = {123.68/256, 116.779/256, 103.939/256}

im = utils.cropUnionBox{
   input = data.input,
   boxes = {subbox, objbox},
   padding = true,
   paddingRGB = vggmeanRGB
}
output = utils.resizeSquare{
   input = im,
   padding = true,
   paddingRGB = vggmeanRGB,
   outputsize = 224,
}

libimage.display(output)

require('fb.debugger').enter()

im = libimage.drawRect(data.input, subbox[1], subbox[2], subbox[3], subbox[4], {
   lineWidth = lineWidth,
   color = {0, 255, 0}
})
im = libimage.drawRect(im, objbox[1], objbox[2], objbox[3], objbox[4], {
   lineWidth = lineWidth,
   color = {255, 0, 0}
})
im = libimage.drawRect(im, unionbox[1], unionbox[2], unionbox[3], unionbox[4], {
   lineWidth = 1,
   color = {0, 0, 255},
})
libimage.display(im)
print(unionbox)
cropim = libimage.crop(im, unionbox[1], unionbox[2], unionbox[3], unionbox[4])
libimage.display(cropim)

input = libimage.crop(data.input, unionbox[1], unionbox[2], unionbox[3], unionbox[4])

require 'loadcaffe'
vggnet = loadcaffe.load('VGG_ILSVRC_19_layers_deploy.prototxt' , 'VGG_ILSVRC_19_layers.caffemodel')
vggnet:evaluate()

utils = require 'utils'
output = utils.resizeSquare{
   input = input,
   padding = true,
   outputsize = 224,
}
feature = vggnet:forward(output)
libimage.display(output)
-- print(feature)
