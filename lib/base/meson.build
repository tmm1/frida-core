base_sources = [
  'session.vala',
  'session-glue.c',
  'rpc.vala',
  'p2p.vala',
  'p2p-glue.c',
  'dbus.vala',
  'promise.vala',
  'socket.vala',
  'socket-glue.c',
]

extra_deps = []
if host_os_family != 'windows'
  extra_deps += [gio_unix_dep]
endif

base = static_library('frida-base-' + api_version, base_sources,
  c_args: frida_component_cflags,
  vala_header: 'frida-base.h',
  vala_vapi: f'frida-base-@api_version@.vapi',
  dependencies: [glib_dep, gobject_dep, gio_dep, libsoup_dep, nice_dep, usrsctp_dep, gee_dep, json_glib_dep, gum_dep] + extra_deps,
  install: true,
  install_dir: [true, header_install_dir, true],
)

base_dep = declare_dependency(
  include_directories: include_directories('.'),
  link_with: base,
  dependencies: [nice_dep, json_glib_dep, gum_dep],
)

base_build_dir = meson.current_build_dir()

pkg = import('pkgconfig')
pkg.generate(base,
  description: 'Frida base library',
)
