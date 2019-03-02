import tink.unit.*;
import tink.unit.Assert.*;
import tink.testrunner.*;
import image.Image;

using tink.CoreApi;

class RunTests {
	static function main() {
		Runner.run(TestBatch.make([
			new TestImageInfo(),
			new TestImageResize()
		])).handle(Runner.exit);
	}
}

@:asserts
class TestImageResize {
	public function new() {}

	function resize(asserts: AssertionBuffer, engine: Engine, extension: String) {
		return Image.resize(
			'tests/assets/sample.$extension', 
			'tests/assets/sample_resized_$engine.$extension', {
				width: 100,
				height: 60,
				engine: engine
			}).next(_ -> 
				Image.getInfo('tests/assets/sample_resized_$engine.$extension')
			).next(info -> {
				asserts.assert(info.width == 100);
				asserts.assert(info.height == 60);
				return Noise;
			});
	}

	function testFileFormats(asserts: AssertionBuffer, engine: Engine, extensions: Array<String>) {
		return Promise.inParallel(
			extensions.map(ext -> resize(asserts, engine, ext))
		).next(_ -> asserts.done());
	}

	public function testImageResizeVips()
		return testFileFormats(asserts, Engine.Vips, ['jpg', 'png', 'webp', 'tiff']);

	public function testImageResizeImageMagick()
		return testFileFormats(asserts, Engine.ImageMagick, ['jpg', 'png', 'bmp', 'gif', 'webp', 'tiff']);

	public function testImageResizeGraphicsMagick()
		return testFileFormats(asserts, Engine.GraphicsMagick, ['jpg', 'png', 'bmp', 'gif', 'webp', 'tiff']);

	#if php
	public function testImageResizeGD()
		return testFileFormats(asserts, Engine.GD, ['jpg', 'png', 'bmp', 'gif', 'webp', 'tiff']);
	#end

}

@:asserts
class TestImageInfo {
	public function new() {}

	public function testJpg() {
		return Image.getInfo('tests/assets/sample.jpg').next(info -> {
			asserts.assert(info.width == 300);
			asserts.assert(info.height == 262);
			asserts.assert(info.format == ImageFormat.Jpg);
			return asserts.done();
		});
	}

	public function testPng() {
		return Image.getInfo('tests/assets/sample.png').next(info -> {
			asserts.assert(info.width == 300);
			asserts.assert(info.height == 262);
			asserts.assert(info.format == ImageFormat.Png);
			return asserts.done();
		});
	}

	public function testWebp() {
		return Image.getInfo('tests/assets/sample.webp').next(info -> {
			asserts.assert(info.width == 320);
			asserts.assert(info.height == 214);
			asserts.assert(info.format == ImageFormat.WebP);
			return asserts.done();
		});
	}

	public function testTiff() {
		return Image.getInfo('tests/assets/sample.tiff').next(info -> {
			asserts.assert(info.width == 300);
			asserts.assert(info.height == 262);
			asserts.assert(info.format == ImageFormat.Tiff);
			return asserts.done();
		});
	}

	public function testGif() {
		return Image.getInfo('tests/assets/sample.gif').next(info -> {
			asserts.assert(info.width == 300);
			asserts.assert(info.height == 262);
			asserts.assert(info.format == ImageFormat.Gif);
			return asserts.done();
		});
	}

	public function testBmp() {
		return Image.getInfo('tests/assets/sample.bmp').next(info -> {
			asserts.assert(info.width == 300);
			asserts.assert(info.height == 262);
			asserts.assert(info.format == ImageFormat.Bmp);
			return asserts.done();
		});
	}
}
