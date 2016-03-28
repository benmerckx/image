# image
Cross platform image manipulation. Supports jpg, gif, png, bmp, tiff, webp.

## Info

### Image.getInfo(path)

Analyzes a given file. Some of the detection code comes from [heaps](https://github.com/ncannasse/heaps). Returns a `Surprise<ImageInfo, Error>`.

```haxe
Image.getInfo('file.jpg').handle(function (res) switch res {
	case Success(data):
    	// {format: ImageFormat.Jpg, width: 100, height: 100}
    case Failure(error):
    	trace(error.message);
});
```

## Resizing and cropping

### Supported tools

Install any of these commandline tools and pass the corresponding engine to the resize method. GD is only supported on php without the need for installing anything, as it uses built-in functions.

- [libvips](https://github.com/jcupitt/libvips)
- [ImageMagick](https://github.com/ImageMagick/ImageMagick)
- [GraphicsMagick](http://www.graphicsmagick.org/)
- [GD](http://php.net/manual/en/book.image.php)

```haxe
enum Engine {
	Vips;
	ImageMagick;
	GraphicsMagick;
	GD;
}
```

### Image.resize(input, output, options)

Returns a `Surprise<Noise, Error>`.

Options being
```haxe
{
	engine: Engine,
	width: Int,
	height: Int,
	?crop: Bool, // Defaults to true
	?focus: {x: Float, y: Float} // Defaults to {x: .5, y: .5}
}
```
Resize and crop a file from the center:

```haxe
Image
.resize('file.jpg', 'thumb.jpg', {engine: Engine.Vips, width: 200, height: 200})
.handle(function (res) switch res {
	case Success(_):
    	trace('Image resized!');
    case Failure(error):
    	trace('Something went wrong: '+error.message);
});
```
