package tests;

using tink.CoreApi;
import helder.Unit.suite;
import helder.Unit.assert;
import image.Image;

final TestInfo = suite(test -> {
  function resize(engine: Engine, extension: String) {
		return Image.resize(
			'tests/assets/sample.$extension', 
			'tests/assets/sample_resized_$engine.$extension', {
				width: 100,
				height: 60,
				engine: engine
			}).next(_ -> 
				Image.getInfo('tests/assets/sample_resized_$engine.$extension')
			).next(info -> {
        assert.is(info.width, 100);
        assert.is(info.height, 60);
				return Noise;
			});
	}

	function testFileFormats(done: Void -> Void, engine: Engine, extensions: Array<String>) {
		return Promise.inParallel(
			extensions.map(ext -> resize(engine, ext))
		).handle(res -> {
      switch res {
        case Failure(e): throw e;
        default: done();
      }
    });
	}

	#if cli
  test('image magick', (done) -> {
    testFileFormats(done, Engine.ImageMagick, ['jpg', 'png', 'bmp', 'gif', 'tiff']);
  });

  test('image magick', (done) -> {
    testFileFormats(done, Engine.GraphicsMagick, ['jpg', 'png', 'bmp', 'gif', 'tiff']);
  });

  test('vips', (done) -> {
    testFileFormats(done, Engine.Vips, ['jpg', 'png', 'webp', 'tiff']);
  });
	#end

	#if php
  test('gd', (done) -> {
    testFileFormats(done, Engine.GD, ['jpg', 'png', 'bmp', 'gif']);
  });
	#end
});