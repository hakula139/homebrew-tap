class ExampleTool < Formula
  url "https://github.com/hakulab/example-tool/releases/download/v1.2.3-rc.1/example-runtime-extended-x86_64-unknown-linux-gnu.tar.gz"
  version "1.2.3-rc.1"
  sha256 "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"

  on_macos do
    url "https://github.com/hakulab/example-tool/releases/download/v1.2.3-rc.1/example-runtime-extended-aarch64-apple-darwin.tar.gz"
    sha256 "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  end

  def install
    bin.install "example"
  end
end
