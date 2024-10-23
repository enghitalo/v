import picohttpparser
import benchmark

const max_iterations = 10
const max_headers = 100

fn main() {


	mut b := benchmark.start()

	// for i := 0; i < max_iterations; i++ {
		mut req := picohttpparser.Request{}
		for j := 0; j < max_headers; j++ {
			_ := req.parse_request('GET / HTTP/1.1\r\nHost: example.com\r\n\r\n') or {
				assert false, 'error while parse request: ${err}'
				0
			}
		}

	// }

	b.measure(r"req.parse_request('GET / HTTP/1.1\r\nHost: example.com\r\n\r\n')!")

}

