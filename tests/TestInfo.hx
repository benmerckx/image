package tests;

import helder.Unit.suite;
import helder.Unit.assert;
import image.Image;

final TestInfo = suite(test -> {
  test('jpg', (done) -> {
    Image.getInfo('tests/assets/sample.jpg')
      .handle(info -> {
        assert.equal(info, Success({width: 300, height: 262, format: Jpg}));
        done();
      });
  });
  
  test('png', (done) -> {
    Image.getInfo('tests/assets/sample.png')
      .handle(info -> {
        assert.equal(info, Success({width: 300, height: 262, format: Png}));
        done();
      });
  });

  test('webp', (done) -> {
    Image.getInfo('tests/assets/sample.webp')
      .handle(info -> {
        assert.equal(info, Success({width: 320, height: 214, format: WebP}));
        done();
      });
  });

  test('tiff', (done) -> {
    Image.getInfo('tests/assets/sample.tiff')
      .handle(info -> {
        assert.equal(info, Success({width: 300, height: 262, format: Tiff}));
        done();
      });
  });

  test('gif', (done) -> {
    Image.getInfo('tests/assets/sample.gif')
      .handle(info -> {
        assert.equal(info, Success({width: 300, height: 262, format: Gif}));
        done();
      });
  });

  test('bmp', (done) -> {
    Image.getInfo('tests/assets/sample.bmp')
      .handle(info -> {
        assert.equal(info, Success({width: 300, height: 262, format: Bmp}));
        done();
      });
  });
});