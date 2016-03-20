package monsoon;

import haxe.io.Bytes;
import haxe.io.Path;
import asys.FileSystem;
import asys.io.File;
import asys.io.FileInput;
import asys.io.FileSeek;
import asys.io.Process;

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
	ImageMagick;
	GraphicsMagick;
}

typedef Options = {
	engine: Engine,
	width: Int,
	height: Int,
	?crop: Bool,
	?focus: {x: Float, y: Float}
}

typedef ImageInfo = {
	width: Int,
	height: Int,
	format: ImageFormat
}

class Image {

	public static function resize(input: String, output: String, options: Options): Surprise<Noise, Error> {
		if (options.crop == null) options.crop = true;
		if (options.focus == null) options.focus = {x: .5, y: .5};
		
		var info: ImageInfo,
			ratio = .0,
			newRatio = .0,
			cropW = 0, cropH = 0,
			width = 0, height = 0,
			sizeRatio = .0,
			path = new Path(input),
			tmp = 'tn_'+path.file+'.'+path.ext,
			xPos = 0,
			yPos = 0;
		
		return
		getInfo(input) >>
		function (res: Outcome<ImageInfo, Error>) return switch res {
			case Success(i):
				info = i;
				ratio = info.width / info.height;
				newRatio = options.width / options.height;
				
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
				
				xPos = Math.round((options.focus.x * info.width) - (cropW / 2));
				yPos = Math.round((options.focus.y * info.height) - (cropH / 2));

				if (xPos + cropW > info.width) xPos = info.width - cropW;
				if (yPos + cropH > info.height) yPos = info.height - cropH;
				if (xPos < 0) xPos = 0;
				if (yPos < 0) yPos = 0;
				
				xPos = Math.round(xPos * sizeRatio);
				yPos = Math.round(yPos * sizeRatio);
				
				var cmd = switch options.engine {
					case Engine.Vips: 'vipsthumbnail';
					case Engine.ImageMagick: 'convert';
					case Engine.GraphicsMagick: 'gm';
				}
				var args = switch options.engine {
					case Engine.Vips:
						[input, '-s', '${width}x${height}', '-c', '-o', tmp];
					case Engine.ImageMagick: 
						[input, 
							'-resize', '${width}x${height}', 
							'-crop', '${options.width}x${options.height}+${xPos}+$yPos',
							'-strip', '+repage', 
						output];
					case Engine.GraphicsMagick: 
						['convert', input, 
							'-resize', '${width}x${height}', 
							'-crop', '${options.width}x${options.height}+${xPos}+$yPos',
							'-strip', '+repage', 
						output];
				}
				var process = new Process(cmd, args);
				process.exitCode() >>
				function(code) return switch code {
					case 0: 
						Success(Noise);
					default:
						Failure(new Error('Resize process exited with: '+code));
				}
			case Failure(e):
				Future.sync(Failure(e));
		} >>
		function(res) return switch res {
			case Success(_):
				switch options.engine {
					case Engine.Vips: 
					default:
						return Future.sync(Success(Noise));
				}
			
				var process = new Process('vips', 
					['crop', 
						Path.join([path.dir, tmp]), 
						output, '$xPos', '$yPos', '${options.width}', '${options.height}'
					]
				);
				
				process.exitCode() >>
				function(code) return switch code {
					case 0: 
						Success(Noise);
					default:
						Failure(new Error('Crop process exited with: '+code));
				}
			case Failure(e):
				Future.sync(Failure(e));
		} >>
		function(res) return switch res {
			case Success(_): 
				switch options.engine {
					case Engine.Vips: 
					default:
						return Future.sync(Success(Noise));
				}
				FileSystem.deleteFile(Path.join([path.dir, tmp]));
			case Failure(e):
				Future.sync(Failure(e));
		}
	}

	public static function getInfo(path: String): Surprise<ImageInfo, Error> {
		var trigger = Future.trigger(),
			width = 0,
			height = 0,
			format: ImageFormat,
			unsupported = 'Unsupported image format';
			
		return
		File.read(path) >>
		function (res: Outcome<FileInput, Error>) switch res {
			case Success(input): 
				switch input.readUInt16() {
					case 0x4952: // WEBP
						input.seek(6, FileSeek.SeekCur);
						if (input.readString(4) != 'WEBP') 
							return Failure(new Error(unsupported));
						format = ImageFormat.WebP;
						switch input.readString(4) {
							case 'VP8 ':
								input.seek(10, FileSeek.SeekCur);
								width = input.readUInt16();
								height = input.readUInt16();
							case 'VP8L':
								input.seek(5, FileSeek.SeekCur);
								var b0 = input.readByte(), b1 = input.readByte(), b2 = input.readByte(), b3 = input.readByte();
								width = 1 + (((b1 & 0x3F) << 8) | b0);
								height = 1 + (((b3 & 0xF) << 10) | (b2 << 2) | ((b1 & 0xC0) >> 6));
							default:
								return Failure(new Error(unsupported));
						}
					case endian if (endian == 0x4949 || endian == 0x4d4d): // TIFF
						input.bigEndian = endian == 0x4d4d;
						if (input.readUInt16() != 42)
							return Failure(new Error(unsupported));
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
						// todo: restrict cycles
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
						// todo: restrict cycles
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
					default:
						return Failure(new Error(unsupported));
				}
				input.close();
				return Success({
					width: width,
					height: height,
					format: format
				});
				
			case Failure(e): 
				return Failure(e);
		}
	}

	public static function main() {
		/*info('bin/val.gif').handle(function(x) switch x {
			case Success(format): trace(format);
			case Failure(e): trace('error');
		});*/
		resize('bin/val.png', 'thumb.png', {engine: Engine.Vips, width: 150, height: 200}).handle(
		function(res) {
			trace(res);
		});
	}
}
