namespace Frida {
	namespace System {
		public static extern Frida.HostProcessInfo[] enumerate_processes ();
		public static extern void kill (uint pid);
	}

	public class ProcessEnumerator {
		private MainContext current_main_context;
		private Gee.ArrayList<EnumerateRequest> pending_requests = new Gee.ArrayList<EnumerateRequest> ();

		public async HostProcessInfo[] enumerate_processes () {
			bool is_first_request = pending_requests.is_empty;

			var request = new EnumerateRequest (() => enumerate_processes.callback ());
			if (is_first_request) {
				current_main_context = MainContext.get_thread_default ();

				try {
					Thread.create<void> (enumerate_processes_worker, false);
				} catch (ThreadError e) {
					error (e.message);
				}
			}
			pending_requests.add (request);
			yield;

			return request.result;
		}

		private void enumerate_processes_worker () {
			var processes = System.enumerate_processes ();

			var source = new IdleSource ();
			source.set_callback (() => {
				current_main_context = null;
				var requests = pending_requests;
				pending_requests = new Gee.ArrayList<EnumerateRequest> ();

				foreach (var request in requests)
					request.complete (processes);

				return false;
			});
			source.attach (current_main_context);
		}

		private class EnumerateRequest {
			public delegate void CompletionHandler ();
			private CompletionHandler handler;

			public HostProcessInfo[] result {
				get;
				private set;
			}

			public EnumerateRequest (owned CompletionHandler handler) {
				this.handler = (owned) handler;
			}

			public void complete (HostProcessInfo[] processes) {
				this.result = processes;
				handler ();
			}
		}
	}

	public class TemporaryDirectory {
		public string path {
			owned get {
				return file.get_path ();
			}
		}
		private File file;

		private bool remove_on_dispose;

		public static TemporaryDirectory system_default {
			owned get {
				return new TemporaryDirectory.with_file (File.new_for_path (get_system_tmp ()), false);
			}
		}

		public TemporaryDirectory () {
			this.file = File.new_for_path (create ());
			this.remove_on_dispose = true;
		}

		protected TemporaryDirectory.with_file (File file, bool remove_on_dispose) {
			this.file = file;
			this.remove_on_dispose = remove_on_dispose;
		}

		~TemporaryDirectory () {
			destroy ();
		}

		public void destroy () {
			if (remove_on_dispose) {
				try {
					this.file.delete ();
				} catch (Error e) {
				}
			}
		}

		private static extern string get_system_tmp ();
		private static extern string create ();
	}

	public class TemporaryFile {
		public string path {
			owned get {
				return file.get_path ();
			}
		}
		private File file;
		private TemporaryDirectory directory;

		public TemporaryFile.from_stream (string name, InputStream istream, TemporaryDirectory? directory = null) throws IOError {
			if (directory != null)
				this.directory = directory;
			else
				this.directory = TemporaryDirectory.system_default;
			this.file = File.new_for_path (Path.build_filename (this.directory.path, name));

			try {
				var ostream = file.create (FileCreateFlags.NONE, null);

				var buf_size = 128 * 1024;
				var buf = new uint8[buf_size];

				while (true) {
					var bytes_read = istream.read (buf);
					if (bytes_read == 0)
						break;
					buf.resize ((int) bytes_read);

					size_t bytes_written;
					ostream.write_all (buf, out bytes_written);
				}

				ostream.close (null);
			} catch (Error e) {
				throw new IOError.FAILED (e.message);
			}
		}

		private TemporaryFile (File file, TemporaryDirectory directory) {
			this.file = file;
			this.directory = directory;
		}

		~TemporaryFile () {
			destroy ();
		}

		public void destroy () {
			if (file != null) {
				try {
					file.delete (null);
				} catch (Error e) {
				}
				file = null;
			}
			directory = null;
		}
	}
}
