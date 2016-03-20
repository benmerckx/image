package monsoon;

import haxe.io.Bytes;
import haxe.io.Path;
/*import sys.FileSystem;
import sys.io.FileSeek;*/
import asys.FileSystem;

using tink.CoreApi;

enum ImageFormat {
	Jpg;
	Png;
	Gif;
	Bmp;
	Tiff;
	WebP;
}

enum Engine {
	Vips;
}

typedef Options = {
	width: Int,
	height: Int,
	?crop: Bool,
	?focus: {x: Float, y: Float}
}

class Image {
	public static var engine;

	public static function resize(input: String, output: String, options: Options) {
		if (engine == null)
			throw "Please set engine before resizing";
		if (options.crop == null) options.crop = true;
		if (options.focus == null) options.focus = {x: .5, y: .5};

		var info = info(input),
			ratio = info.width / info.height,
			newRatio = options.width / options.height,
			cropW = 0, cropH = 0,
			width = 0, height = 0,
			sizeRatio = .0;

		// Compare ratios
        if (ratio > newRatio) {
            // Original image is wider
            height = options.height;
            width = Math.round(options.height * ratio);
            cropH = info.height;
            cropW = Math.round(info.width / width * options.width);
			sizeRatio = options.height / info.height;
        } else {
            // Equal width or smaller
            height = Math.round(options.width / ratio);
            width = options.width;
            cropW = info.width;
            cropH = Math.round(info.height / height * options.height);
			sizeRatio = options.width / info.width;
        }

		var handler = new ProcessHandler(),
			path = new Path(input);

		handler
		.process('vipsthumbnail ? -s ${width}x${height} -c -o tmptn_%s.png', [input])
		.handle(function(status)
			return switch status {
				case Failure(msg):
					throw msg;
				default:
					var xPos = (options.focus.x * info.width) - (cropW / 2),
			        	yPos = (options.focus.y * info.height) - (cropH / 2);

					if (xPos + cropW > info.width) xPos = info.width - cropW;
			        if (yPos + cropH > info.height) yPos = info.height - cropH;
			        if (xPos < 0) xPos = 0;
			        if (yPos < 0) yPos = 0;
					xPos = Math.round(xPos * sizeRatio);
					yPos = Math.round(yPos * sizeRatio);
					
					handler
					.process('vips crop ? ? $xPos $yPos ${options.width} ${options.height}',
						['tmptn_'+path.file+'.'+path.ext, output]
					)
					.handle(function(status)
						switch status {
							case Failure(msg):
								throw msg;
							default:
								FileSystem.deleteFile('tmptn_'+path.file+'.'+path.ext);
						}
					);
			}
		);
	}

	public static function info(path: String) {
		var input = BytesInput.fromFile(path),
			width = 0,
			height = 0,
			format: ImageFormat;

		switch input.readUInt16() {
			case 0x4952: // WEBP
				input.seek(6, FileSeek.SeekCur);
				if (input.readString(4) != 'WEBP') 
					throw 'Unsupported image format';
				format = ImageFormat.WebP;
				switch input.readString(4) {
					case 'VP8 ':
						input.seek(10, FileSeek.SeekCur);
						width = input.readUInt16();
						height = input.readUInt16();
					case 'VP8L':
						input.seek(5, FileSeek.SeekCur);
						var b0 = input.readByte(), b1 = input.readByte(), b2 = input.readByte(), b3 = input.readByte();
						width = 1 + (((b1 & 0x3F) << 8) | b0); // todo: check on nodejs
						height = 1 + (((b3 & 0xF) << 10) | (b2 << 2) | ((b1 & 0xC0) >> 6));
					default:
				}
			case endian if (endian == 0x4949 || endian == 0x4d4d): // TIFF
				input.bigEndian = endian == 0x4d4d;
				if (input.readUInt16() != 42)
					throw 'Unsupported image format';
				format = ImageFormat.Tiff;
				var offset = input.readInt32();
				input.seek(offset, FileSeek.SeekBegin);
				var count = input.readUInt16();
				while (count-- > 0 && (width == 0 || height == 0)) {
					var tag = input.readUInt16(),
						type = input.readUInt16(),
						values = input.readInt32();
					var value = switch type {
						case 3: var t = input.readUInt16(); input.readUInt16(); t;
						default: input.readInt32();
					}
					switch tag {
						case 256: width = value;
						case 257: height = value;
						default:
					}
				}
			case 0x4d42: // BMP
				format = ImageFormat.Bmp;
				input.seek(16, FileSeek.SeekCur);
				width = input.readInt32();
				height = input.readInt32();
			case 0x5089: // PNG
				format = ImageFormat.Png;
				var tmp = Bytes.alloc(256);
				input.bigEndian = true;
				input.readBytes(tmp, 0, 6);
				while (true) {
					var dataLen = input.readInt32();
					if (input.readInt32() == ('I'.code << 24) | ('H'.code << 16) | ('D'.code << 8) | 'R'.code ) {
						width = input.readInt32();
						height = input.readInt32();
						break;
					}
					while (dataLen > 0) {
						var k = dataLen > tmp.length ? tmp.length : dataLen;
						input.readBytes(tmp, 0, k);
						dataLen -= k;
					}
					var crc = input.readInt32();
				}
			case 0xD8FF: // JPG
				format = ImageFormat.Jpg;
				input.bigEndian = true;
				while (true) {
					switch input.readUInt16() {
						case 0xFFC2, 0xFFC0:
							var len = input.readUInt16();
							var prec = input.readByte();
							height = input.readUInt16();
							width = input.readUInt16();
							break;
						default:
							input.seek(input.readUInt16() - 2, FileSeek.SeekCur);
					}
				}
			case 0x4947: // GIF
				format = ImageFormat.Gif;
				input.readInt32();
				width = input.readUInt16();
				height = input.readUInt16();
			case _:
				throw 'Unsupported image format';
		}

		return {
			width: width,
			height: height,
			format: format
		}
	}

	public static function main() {
		engine = Vips;
		trace(info('bin/preview.jpg'));
		//resize('bin/2_webp_ll.webp', 'thumb.png', {width: 150, height: 200});
	}
}
