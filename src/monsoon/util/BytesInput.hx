package sharper.util;

import haxe.io.Bytes;
import sys.io.FileSeek;

class BytesInput {
	#if nodejs
	var buffer: js.node.Buffer;
	var position = 0;
	
	public var bigEndian : Bool;
	
	public function new(path) {
		bigEndian = false;
		buffer = js.node.Fs.readFileSync(path);
	}
	
	public function seek(length: Int, from: FileSeek)
		switch from {
			case FileSeek.SeekBegin: position = length;
			case FileSeek.SeekCur: position += length;
			case FileSeek.SeekEnd: position = buffer.length - length;
		}
	
	public function readBytes(s: Bytes, pos: Int, len: Int): Int {
		var i = 0;
		while (i < len) {
			s.set(pos+i, readByte());
			i++;
		}
		return len;
	}
	
	inline public function readByte()
		return callBufferMethod('readInt', 1);
	
	inline public function readUInt16()
		return callBufferMethod('readUInt16', 2);
	
	inline public function readInt32()
		return callBufferMethod('readInt32', 4);
	
	public function readString(len: Int) {
		var data = Bytes.alloc(len);
		readBytes(data, 0, len);
		return data.toString();
	}
		
	function callBufferMethod(method: String, increase: Int) {
		method += bigEndian?'BE':'LE';
		var value = untyped buffer[method](position);
		seek(increase, FileSeek.SeekCur);
		return value;
	}
	#end
	
	public static function fromFile(path) {
		#if nodejs
		return new BytesInput(path);
		#else
		return sys.io.File.read(path);
		#end
	}
}