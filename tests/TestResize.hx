package tests;

using tink.CoreApi;
import helder.Unit.suite;
import helder.Unit.assert;
import image.Image;

final TestResize = suite(test -> {
  function resize(engine: Engine, extension: String) {
		return Image.resize(
			'tests/assets/sample.$extension', 
			'tests/assets/sample_resized_$engine.$extension', {
				width: 100,
				height: 60,
				engine: engine
			}).next(_ -> 
				Image.getInfo('tests/assets/sample_resized_$engine.$extension')
			);
	}

	function testFileFormats(engine: Engine, extensions: Array<String>) {
		for (ext in extensions) {
			test('$engine $ext', done -> {
				resize(engine, ext).handle(res -> {
					switch res {
						case Success(info):
							assert.is(info.width, 100);
							assert.is(info.height, 60);
							done();
						case Failure(e):
							throw e;
					}
				});
			});
		}
	}

	#if cli
  testFileFormats(Engine.ImageMagick, ['jpg', 'png', 'bmp', 'gif', 'tiff']);
	testFileFormats(Engine.GraphicsMagick, ['jpg', 'png', 'bmp', 'gif', 'tiff']);
  testFileFormats(Engine.Vips, ['jpg', 'png', 'webp', 'tiff']);
	#end

	#if php
  testFileFormats(Engine.GD, ['jpg', 'png', 'bmp', 'gif']);
	#end
});