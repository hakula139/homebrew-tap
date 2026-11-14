class ExampleTool < Formula
  url "{{base}}/example-runtime-extended-x86_64-unknown-linux-gnu.tar.gz"
  version "{{version}}"
  sha256 "{{linux_x86_sha}}"

  on_macos do
    url "{{base}}/example-runtime-extended-aarch64-apple-darwin.tar.gz"
    sha256 "{{mac_arm_sha}}"
  end

  def install
    bin.install "example"
  end
end
