import tink.unit.*;
import tink.unit.Assert.*;
import tink.testrunner.*;
import image.Image;

class RunTests {
	static function main() {
		Runner.run(TestBatch.make([new TestImageInfo(),])).handle(Runner.exit);
	}
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
		return Image.getInfo('tests/assets/sample.tif').next(info -> {
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
