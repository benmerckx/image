package sharper.util;

import sys.io.Process;

using tink.CoreApi;
using Lambda;

class ProcessHandler {

	public function new() {}

	public function process(command: String, args: Array<String>): Surprise<Noise, String> {
		var parts = command.split(' '),
			i = 0;

		parts = parts.map(function(part) {
			if (part == '?') return args[i++];
			return part;
		});

		var process = run(parts.shift(), parts);
		var err = process.stderr.readAll();
		var msg = err.toString();
		if (msg != '') {
			return Future.sync(Failure(msg));
		}

		return Future.sync(Success(Noise));
	}

	function run(util, args)
		return new Process(util, args);

}
