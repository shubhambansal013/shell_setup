# BUILD file for the logrotate wrapper script

package(default_visibility = ["//visibility:private"])

sh_binary(
    name = "logrotate_wrapper",
    srcs = ["logrotate.sh"],
    data = [
        "logrotate.conf",
        "README.md",
    ],
)

exports_files([
    "logrotate.conf",
    "README.md",
])
